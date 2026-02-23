# Updated version by Richard Howey

suppressMessages(library(tidyverse))
suppressMessages(library(gridExtra))
suppressMessages(library(shiny))
library(shinyFiles)
#suppressMessages(library(dqshiny))
source("utils_clumping.R")
source("utils_plotting.R")
source("utils_shiny.R")
source("utils_manhattan.R")

print(getwd())

#data_dir <- "../../../pbc_analysis/data" #"../data"
#res_dir <- "../../../pbc_analysis/results" #../results"
lmm_dir <- "../data/lmm"
gwas_dir <- "../../../pbc_analysis/results_gwas"
use_plink_gwas <- TRUE

annotations <- load_annotations(".")
genes <- unique(annotations$Exons.canonical$name2)

# create user interface
ui <- fluidPage(theme = "theme.css",

  # title
  headerPanel('KnockoffGWAS discovery view'),
  
  # side panel with inputs, error messages, and information box
  fluidRow(
    column(3,
           h4("Step 1: Select results directory."),
           wellPanel(
             shinyDirButton(
               id = "results_dir",
               label = "Choose directory",
               title = "Select results folder",
               multiple = FALSE
             ),
            
           
           verbatimTextOutput("results_dir_path"),
           tags$small(
             tags$strong("Selected directory:"),
             textOutput("res_dir_text")
           )),
      h4("Step 2: Select a chromosome."),
      wellPanel(
        #selectInput(inputId = 'phenotype', label = 'Phenotype', choices = c(phenotypes)),
        fluidRow(
        column(6,
               verticalLayout(uiOutput("ui_chr_select"),
                              actionButton("load.results", "Load results")
                             )
              )
        )
      ),
      h4("Optional Step 3: Type a gene."),
      wellPanel(
        fluidRow( 
          
          column(6,
                    verticalLayout(uiOutput("ui_gene_select"),
                                   actionButton("zoom.gene", "Zoom to gene")
                                   )
                 )
        )
      ),
      h4("Optional Step 4: Refine the locus."),
      wellPanel(
        fluidRow(
          column(6,actionButton("zoom.in", "Zoom in (slider)")),
          column(6,actionButton("zoom.out", "Zoom out (x10)"))          
        )
      ),
      h4("Optional Step 5: Export plots to results directory."),
      wellPanel(
        fluidRow(
          column(6, actionButton("export_manhattan", "Export Manhattan Plot")),
          column(6, actionButton("export_chicago", "Export Chicago Plot"))
          ),
        br(), 
        fluidRow(
          column(6,actionButton("export_all", "Export All Plots"))
        )
      ),
      actionButton("info", "?"),
      span(textOutput("message"), style="color:red"),
      absolutePanel(
        bottom = 0, left = 0, width = "24%",
        fixed = TRUE,        
        div(
          style="padding: 8px; border: 5px solid #CCC; background: #FFFFFF;", 
          HTML("This website presents the results of the KnockoffGWAS methodology. See <a href=\"https://msesia.github.io/knockoffgwas\" target=\"_blank\"/>this webpage</a> 
            for more information.")
        )
      )
  ),

  # main panel displaying results
  column(9,
    tabsetPanel(type = "tabs", id = "Tabset",
                tabPanel(title = "Chromosome", value = "manhattan", 
                         h4(textOutput("placeholder.manhattan")),
                         plotOutput('plot.manhattan', width = "100%", height = "700px")),
                tabPanel(title = "Locus", value = "manhattan.chr", 
                         h4(textOutput("placeholder.locus")),
                         
                         splitLayout(width = "100%", cellWidths = c("4.6%", "76.1%", "19.3%"), 
                                     NULL, uiOutput("slider"), NULL),
                         
                         plotOutput('plot.annotations', width = "100%", height = "700px")
                         )
    )
  )
)
)


# back-end code
server <- function(input, output, session) {

  ## reactive holder for user choice
  res_dir_rv <- reactiveVal("/path/to/results")
  
  app_dir  <- normalizePath(getwd())
  root_dir <- normalizePath(file.path(app_dir, "..", "..", ".."))
  volumes  <- c(Root = root_dir)
  
  shinyDirChoose(input, "results_dir", roots = volumes, session = session)
  
  observeEvent(input$results_dir, {
    res_dir_rv(parseDirPath(volumes, input$results_dir))
  })
  
  output$res_dir_text <- renderText({
    res_dir_rv()
  })
  
  output$placeholder.manhattan <- renderText({"[Select a results directory and chromosome to get started.]"})
  output$placeholder.locus <- renderText({"[Select a gene to produce locus view.]"})
  # all parameters required to describe state of the app  
  state <- reactiveValues(
                         association_results = NULL,
                         chr = NULL,
                         res_dir = NULL, 
                         max.BP = NULL,
                         window.left = NULL, 
                         window.right = NULL,
                         slider.left = NULL,
                         slider.right = NULL,
                         highlight.gene = NULL)
  
  # what to do if "Info" button is pressed
  observeEvent(input$info, {
    if(input$Tabset == "manhattan"){
      box.title <- "Information on low-resolution results"
      if(use_plink_gwas) {
        box.message.1 <- "Top: Manhattan plot with BOLT-LMM p-values."
      } else {
        box.message.1 <- "Top: Manhattan plot with Plink p-values." 
      }
      box.message.2 <- "Bottom: Manhattan plot with KnockoffGWAS test statistics at low-resolution."
      box.message <- sprintf("%s<br>%s", box.message.1, box.message.2)
    } else{
      box.title <- "Information on high-resolution results"
      if(use_plink_gwas) {
        box.message.1 <- "Top: Manhattan plot with BOLT-LMM p-values."
      } else {
        box.message.1 <- "Top: Manhattan plot with Plink p-values." 
      }
      box.message.2 <- "Middle: Chicago plot with KnockoffGWAS test statistics at multiple resolutions."
      box.message.3 <- "Bottom: Functional annotations and gene positions."
      box.message <- sprintf("%s<br>%s<br>%s", box.message.1, box.message.2, box.message.3)
    }

    showModal(modalDialog(
      title = box.title,
      HTML(box.message)
    ))
  })
  
  # what to do if "Load association results" button is pressed
  observeEvent(input$load.results, {
    chr <- input$chr
    # clear error message
    output$message <- NULL
    # switch to the appropriate tab
    updateTabsetPanel(session, inputId = "Tabset", selected = "manhattan")
    # clear placeholder
    output$placeholder.manhattan <- NULL
    # check if chr has changed; if so, clear lower-level variables and 
    # load association results for new chr
    current_dir <- res_dir_rv()
    
    need_reload <-
      is.null(state$association_results) ||
      is.null(state$chr) ||
      is.null(state$res_dir) ||
      chr != state$chr ||
      current_dir != state$res_dir
    
    if (need_reload) {
      
        state$chr <- chr
        state$highlight.gene <- NULL
        state$max.BP <- NULL
        state$window.left <- NULL
        state$window.right <- NULL
        state$slider.left <- NULL
        state$slider.right <- NULL
        output$plot.annotations <- NULL # important: clear Chicago plot
        output$placeholder.locus <- renderText({"[Select a gene to produce locus view.]"})
        file_prefix<-paste0("results_chr",chr,"_chr",chr)
        state$association_results <- load_association_results(res_dir_rv(), lmm_dir, file_prefix)
      
    } else{
        state$chr <- chr
        file_prefix<-paste0("results_chr",chr,"_chr",chr)
        withProgress(message = 'Loading results...', value = 0, {
          state$association_results <- load_association_results(res_dir_rv(), lmm_dir, file_prefix)
        })
    }
    
    # Update to use Plink GWAS results
    if(use_plink_gwas) {
      withProgress(message = 'Loading Plink GWAS results...', value = 0, {
        state$association_results <- update_lmm_from_plink(
          association_results = state$association_results,
          gwas_dir  = gwas_dir,
          type = "logistic"
        )
      })
      
    }
    
    # Check if results loaded
    if(is.null(state$association_results))
    {
      showNotification("Unable to load results!", type = "message")
      return(NULL)
    }
    
    # produce plot
    
    output$plot.manhattan <- renderPlot({
      
      req(
        state$association_results,
        state$window.left,
        state$window.right,
        state$chr
      )
      
      withProgress(message = 'Rendering plot...', value = 0, {
        suppressWarnings(
        plot_manhattan_knockoffs(state$association_results$LMM,
                                 state$association_results$Pvalues,
                                 ytrans="identity"))
      })
    })
    
  
    
    # Produce "Locus" plot
    error <- TRUE
    # check if association data are loaded
    if(is.null(state$chr) || is.null(state$association_results)){
      output$message <- renderText({"Before clicking this button, first select a 
          chromosome and load association results."})
    } else{
      # check if valid chromosome number was entered
      chr <- as.integer(input$chr)
      if(is.na(chr) || is.null(chr)){
        error <- TRUE
      } else{
        if(!(chr %in% 1:22)){
          error <- TRUE
        } else{
          error <- FALSE
        }
      } 
      if(error){
        output$message <- renderText({"Type a chromosome number between 1 and 22."})
      } else{
        # clear error message
        output$message <- NULL
        # clear placeholder
        output$placeholder.locus <- NULL
        # clear highlighted gene if chromosome has changed
        if(!is.null(state$chr)){
          if(state$chr != chr){
            state$chr <- chr
            state$highlight.gene <- NULL
          }
        } else{
          state$chr <- chr
          state$highlight.gene <- NULL
        }
        # set window parameters to show whole chromosome
        chr.boundaries <- find_chr_boundaries(state$association_results, state$chr)
        state$min.BP <- chr.boundaries$min.BP
        state$max.BP <- chr.boundaries$max.BP
        state$chr <- chr
        state$window.left <- state$min.BP
        state$window.right <- state$max.BP
        state$slider.left <- state$window.left
        state$slider.right <- state$window.right
        updateTabsetPanel(session, inputId = "Tabset", selected = "manhattan.chr")
        
        
        output$plot.annotations <- renderPlot({
          
          req(
            state$association_results,
            state$window.left,
            state$window.right,
            state$chr
          )
          
          withProgress(message = 'Rendering plot...', value = 0, {
            suppressWarnings(
            plot_combined_state(state, annotations))
          })
          
        })
        
      }
    }
    
    
  })

  # what to do if "Zoom to gene" button is pressed
  observeEvent(input$zoom.gene,{
    
    # check if association data are loaded
    if(is.null(state$chr) || is.null(state$association_results)){
      output$message <- renderText({"Before clicking this button, first select a chromosome and
        load association results."})
    } else{
       if(input$gene %in% genes){ # check if valid gene name was entered
         withProgress(message = 'Finding location of gene...', value = 0, {
           # clear placeholder
           output$placeholder.locus <- NULL
           # clear error message
           output$message <- NULL
           # set chromosome appropriately
           filtered_exons <- filter(annotations$Exons.canonical, name2==input$gene)
           state$chr <- filtered_exons$chrom[1]
           print(head(state$association_results))
           state$max.BP <- max(state$association_results$Stats$BP.max) #max(filter(state$association_results$LMM, CHR==state$chr)$BP)
           # set center of gene to be center of window
           gene_min <- min(filtered_exons$txStart)
           gene_max <- max(filtered_exons$txEnd)
           window.center <- (gene_min + gene_max)/2
           # choose a window of width 1Mb
           state$window.left <- max(0, window.center - 0.25e6)
           state$window.right <- min(window.center + 0.25e6, state$max.BP)
           # adjust slider appropriately
           state$slider.left <- state$window.left
           state$slider.right <- state$window.right
           # set highlighted gene
           state$highlight.gene <- input$gene
           # switch to the appropriate tab
           updateTabsetPanel(session, inputId = "Tabset", selected = "manhattan.chr")
         })
         # produce Chicago plot
         output$plot.annotations <- renderPlot({
           withProgress(message = 'Rendering plot...', value = 0, {
               plot_combined_state(state, annotations)
             })
         })
       } else{
         output$message <- renderText({"Type a valid gene name."})
       }
    }
  })
  
  # what to do if "Zoom in" button is pressed
  observeEvent(input$zoom.in,{
    # check if association results are loaded
    if(is.null(state$chr) || is.null(state$association_results)){
      output$message <- renderText({"Before clicking this button, load association results for
        a chromosome and then choose a gene."})
    } else{
      # check if window is chosen
      if(is.null(state$window.left) || is.null(state$window.right)){
        output$message <- renderText({"Before clicking this button, choose a gene."})
      } else{
        # switch to appropriate tab
        updateTabsetPanel(session, inputId = "Tabset", selected = "manhattan.chr")
        output$message <- NULL
        # reset window based on slider
        state$window.left <- input$window[1]*1e6
        state$window.right <- input$window[2]*1e6
        state$slider.left <- state$window.left
        state$slider.right <- state$window.right
        # produce plot
        output$plot.annotations <- renderPlot({
          suppressWarnings(
          withProgress(message = 'Rendering plot...', value = 0, {
              plot_combined_state(state, annotations)
            }))
        })
      }
    }
  })

  # what to do if "Zoom out" button is pressed
  observeEvent(input$zoom.out, {
    # check if association results are loaded
    if(is.null(state$chr) || is.null(state$association_results)){
      output$message <- renderText({"Before clicking this button, load association results for
        a chromosome and then choose a gene."})
    } else{
      if(is.null(state$window.left) || is.null(state$window.right)){
        output$message <- renderText({"Before clicking this button, choose a gene."})
      } else{
        # switch to appropriate tab
        updateTabsetPanel(session, inputId = "Tabset", selected = "manhattan.chr")
        # clear error message
        output$message <- NULL
        # set new window parameters
        window.center <- 0.5*(state$window.left + state$window.right)
        window.width <- 10*(state$window.right - state$window.left)
        state$window.left <- max(window.center - 0.5*window.width, state$min.BP)
        state$window.right <- min(window.center + 0.5*window.width, state$max.BP)
        # adjust slider
        state$slider.left <- state$window.left
        state$slider.right <- state$window.right
        # produce plot
        output$plot.annotations <- renderPlot({
          withProgress(message = 'Rendering plot...', value = 0, {
            suppressWarnings(
              plot_combined_state(state, annotations))
            })
        })
      }
    }
  })
  
  # produce slider UI element
  output$slider <- renderUI({
    # make sure window parameters are set
    if(!is.null(state$chr) & 
       !is.null(state$window.left) & 
       !is.null(state$window.right) & 
       !is.null(state$slider.left) &
       !is.null(state$slider.right)){
      
      # Make sure that the two ends of the slider do not overlap
      if(state$window.right<=state$window.left+0.2e6) {
        state.center <- max(0,(state$window.left+state$window.right)/2)
        state$window.left <- max(0,state.center-0.1e6)
        state$window.right <- state.center+0.1e6
        state$slider.left <- state$window.left
        state$slider.right <- state$window.right
      }
      
      # convert from BP to Mb
      window.left.Mb <- round(1e-6*state$window.left, 1)
      window.right.Mb <- round(1e-6*state$window.right, 1)
      slider.left.Mb <- round(1e-6*state$slider.left, 1)
      slider.right.Mb <- round(1e-6*state$slider.right, 1)
      
      # create slider
      sliderInput("window", label = NULL,
                  width = "99%", min = window.left.Mb, max = window.right.Mb,
                  step = min(0.5, window.right.Mb - window.left.Mb)/100,
                  value = c(slider.left.Mb, slider.right.Mb))
    } else{
      NULL
    }
  })
  
  # produce gene selection UI element
  output$ui_gene_select <- renderUI({
   autocomplete_input("gene", label = "Gene", value = state$highlight.gene,
                      options = genes, width = "90%")
  })
  
  # produce chromosome selection UI element
  output$ui_chr_select <- renderUI({textInput(inputId = 'chr', width = "90%", 
                                              value = state$chr, label = 'Chromosome')
  })
  
  # Produce plots
  observeEvent(input$export_manhattan, {
    
    if (!dir.exists(res_dir_rv())) {
      dir.create(res_dir_rv(), recursive = TRUE)
    }
    
    today <- format(Sys.time(), "%Y-%m-%d-%H_%M_%S")
    
    req(
      state$chr,
      state$association_results,
      state$association_results$LMM
    )
    
    df_lmm <- state$association_results$LMM
    df_clumped <- state$association_results$LMM.clumped
    
    if (!is.null(df_lmm) && nrow(df_lmm) > 0) {
      
      png(
        file.path(res_dir_rv(), paste0("manhattan-", today, ".png")),
        2800, 1400, res = 150
      )
      on.exit(dev.off(), add = TRUE)
      
      p <- plot_pvalues(
        state$chr,
        state$window.left,
        state$window.right,
        df_lmm,
        df_clumped
      )
      
      print(p)
      
      showNotification(
        "Manhattan plot exported successfully",
        type = "message"
      )
      
    } else {
      
      showNotification(
        "No Manhattan results to plot!",
        type = "message"
      )
      
    }
  })
  
  
  observeEvent(input$export_chicago, {
    
    if (!dir.exists(res_dir_rv())) {
      dir.create(res_dir_rv(), recursive = TRUE)
    }
    
    today <- format(Sys.time(), "%Y-%m-%d-%H_%M_%S")
    
    req(
      state$chr,
      state$association_results,
      state$association_results$Discoveries
    )
    
    df <- state$association_results$Discoveries
    
    if (!is.null(df) && nrow(df) > 0) {
      
      png(
        file.path(res_dir_rv(), paste0("chicago-", today, ".png")),
        2800, 1400, res = 150
      )
      
      p <- plot_chicago(
        state$chr,
        state$window.left,
        state$window.right,
        df
      )
      
      print(p)
      dev.off()
      
      showNotification("Plots exported successfully", type = "message")
      
    } else {
      
      showNotification("No Chicago results to plot!", type = "message")
      
    }
  })
  
  
  observeEvent(input$export_all, {
    
    if (!dir.exists(res_dir_rv())) dir.create(res_dir_rv(), recursive = TRUE)
    
    today <- format(Sys.time(), "%Y-%m-%d-%H_%M_%S")
    
    req(state$chr, state$association_results)
    
    png(file.path(res_dir_rv(), paste0("all-",today,".png") ), 2800, 1400, res=150)
    
    # REBUILD the plot fresh
    p<-plot_combined_state(state, annotations)
    
    print(p)
    dev.off()
    
    showNotification("Plots exported successfully", type = "message")
  })
  
  
} # end of server function

shinyApp(ui = ui, server = server)
