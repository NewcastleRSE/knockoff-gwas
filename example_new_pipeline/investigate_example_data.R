# Investigate chr21 and chr22 data

setwd(paste0("C:\\Users\\",Sys.getenv("USERNAME"),"\\OneDrive - Newcastle University\\StatGen\\work-other\\KnockOff\\KnockoffGWAS\\example_new_pipeline"))

# Load chr21

chr21<-read.table("example_chr21.ped", header=FALSE)

chr22<-read.table("example_chr22.ped", header=FALSE)

row_no<-3

row1_22<-chr22[row_no,]

results22<-rep(0, 1000)

for(row in 1:1000) {
  results22[row]<-sum(row1_22[7:2006] == chr22[row,7:2006])
  
}

results22


row1_21<-chr21[row_no,]

results21<-rep(0, 1000)

for(row in 1:1000) {
  results21[row]<-sum(row1_21[7:2006] == chr21[row,7:2006])
  
}

results21

par(mfrow=c(1,2))
hist(results21)
hist(results22)

# invest vcf

v21<-read.table("example_chr21.vcf", skip=6, header=TRUE)

# invest genetic map

map<-read.table("example_map_chr21.txt", header=TRUE)


