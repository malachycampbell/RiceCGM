setwd("~/Desktop/Aus_Drought_RRBLUP/phenotypes/RawData_BB/")

library(plyr)
library(reshape2)

IDs=read.csv("IdList.csv")
WUE=read.csv("~/Desktop/Aus_Drought_RRBLUP/phenotypes/CleanedData/WUE.WU_cleaned.csv")
WUE$Projected.Shoot.Area=NULL

##Read in the data and split the dataset into top view data and side view data.
##Since there are two ide views I will average the two.
AllExp=read.csv("AllExpAllTraits.csv")
SV=AllExp[c("Exp", "Snapshot.ID.Tag", "DayOfImaging",
                     "RGB_SV1.Height",
                     "RGB_SV2.Height")]

TV=AllExp[c(colnames(AllExp)[1:13],
            "RGB_TV.Convex.Hull.Area",
            "RGB_TV.Area")]

SV=melt(SV, id.vars=c(colnames(SV)[1:3]))

##Drop the image side view labels (i.e. SV1 and SV2)
SV$variable=sub("SV1", "", SV$variable)
SV$variable=sub("SV2", "", SV$variable)

##Take the average of the two side views for each metric
SV=ddply(SV, .(Exp, Snapshot.ID.Tag, DayOfImaging, variable), summarise, Mean=mean(value, na.rm=T))

##Convert it back to a wide format and merge it with the top view data
SV=dcast(SV, Exp + Snapshot.ID.Tag + DayOfImaging ~ variable, value.var = "Mean")
AllExp=merge(TV, SV, by=c("Exp", "Snapshot.ID.Tag", "DayOfImaging"))

##For experiments that ended on weekends/holidays the plants were allowed 
##to stay on the system and were continued to be imaged. So the experiments 
##have 20-23 days of imaging. I'll keep only the first 20 days.
AllExp$DayOfImaging=as.character(AllExp$DayOfImaging)
AllExp$DayOfImaging=as.numeric(AllExp$DayOfImaging)
AllExp=AllExp[AllExp$DayOfImaging < 21 ,]

##Here I will calculate Density. Density can be used as a measure of the canopy density. 
##It is the ratio of the plants convex hull area from the top view to the total number 
##of pixels from the top view. The greater the values the leass dense the canopy is, 
##so we should be able to see a lot of the soil from the top view.
AllExp$Density=AllExp$RGB_TV.Area / AllExp$RGB_TV.Convex.Hull.Area

##Next, I will calculate two measures for the plant grwoth habit. Growth habit describes 
##whether the growth pattern is upright or prostrate. Here the distance from the top of 
##the pot to the tallest plant pixel in the image will be used as the denominator and the 
##numerator is the convex hull area of the top view. Larger values should represent a wider 
##plant. Breeders would target something that is more upright to increase the planting density 
##in the feild and reduce the shading between the neighbors.
AllExp$GH2=AllExp$RGB_TV.Convex.Hull.Area / AllExp$RGB_.Height

write.csv(AllExp, "AllExp_MorphTraits_RAW.csv", row.names = F)

#Outlier detection and removal
##Define some functions to detect outliers. I will use the 1.5*IQR rule.
outlier.detection.up <- function(x){
  lowerq = quantile(x, na.rm=T)[2]
  upperq = quantile(x, na.rm=T)[4]
  iqr = upperq - lowerq 
  extreme.threshold.upper = (iqr * 1.5) + upperq
  return(extreme.threshold.upper)
}

outlier.detection.low <- function(x){
  lowerq = quantile(x, na.rm=T)[2]
  upperq = quantile(x, na.rm=T)[4]
  iqr = upperq - lowerq 
  extreme.threshold.lower = lowerq - (iqr * 1.5)
  return(extreme.threshold.lower)
}

##Read in the raw data
AllExp=read.csv("AllExp_MorphTraits_RAW.csv")
AllExp=melt(AllExp, id.vars=colnames(AllExp)[1:12])

##Remove Inf values
AllExp$value[is.infinite(AllExp$value)] <- NA

dim(AllExp[AllExp$value  ==  0 ,]) ##440 measurements with 0 values

AllExp=AllExp[AllExp$value  !=  0 ,]

##Calculate the outlier threshold for each trait at each time point
ddout=ddply(AllExp, .(Exp, DayOfImaging, Watering.Regime, variable), summarise,
            Upper=outlier.detection.up(value),
            Lower=outlier.detection.low(value))

##For each trait, timepoint, treatment and experiment flag plants that are potentially outliers
out.list=list()
for(k in 1:length(unique(AllExp$variable))){
  tmp.df=AllExp[AllExp$variable %in% unique(AllExp$variable)[k] ,]
  out.df=ddout[ddout$variable %in% unique(AllExp$variable)[k] ,]
  for (i in 1:3){
    tmp.e=tmp.df[tmp.df$Exp %in% paste0("E", i) ,]
    out.e=out.df[out.df$Exp %in% paste0("E", i) ,]
  
    for(t in 1:2){
      treat=unique(AllExp$Watering.Regime)[t]
      tmp.t=tmp.e[tmp.e$Watering.Regime %in% treat ,]
      out.t=out.e[out.e$Watering.Regime %in% treat ,]
    
      for(j in 1:20){
        tmp.d=tmp.t[tmp.t$DayOfImaging %in% j ,]
        out.d=out.t[out.t$DayOfImaging %in% j ,]
      
        foo=tmp.d[tmp.d$value <= out.d$Lower ,]
        foo=rbind(foo, tmp.d[tmp.d$value >= out.d$Upper ,])
      
        out.list[[paste0(i,j,k)]]=foo
      }
    }
  }
}
out.list=ldply(out.list)

out.list=unique(out.list[c("Exp", "Snapshot.ID.Tag", "variable")])

out.list$Key=paste0(out.list$Exp, "_", out.list$Snapshot.ID.Tag)

out.list=out.list[!is.na(out.list$Exp) ,]

AllExp$Key=paste0(AllExp$Exp, "_", AllExp$Snapshot.ID.Tag)

##Calculate the mean at each time point for each trait.
dd.out=ddply(AllExp, .(Exp, DayOfImaging, variable, Watering.Regime), summarise, Mean=mean(value, na.rm=T))

AllExp=AllExp[order(AllExp$Snapshot.ID.Tag, AllExp$variable, AllExp$DayOfImaging) ,]

pdf("Outliers_Raw.pdf", h=5, w=8)
for(i in 1:nrow(out.list)){
  tmp=out.list[i,]
  Exp.tmp=AllExp[AllExp$Key ==  tmp$Key ,]
  dd.tmp=dd.out[dd.out$Exp %in% Exp.tmp$Exp ,]
  dd.tmp=dd.tmp[dd.tmp$Watering.Regime %in% Exp.tmp$Watering.Regime ,]
  dd.tmp=dd.tmp[dd.tmp$variable %in% tmp$variable ,]
  Exp.tmp=Exp.tmp[Exp.tmp$variable %in% tmp$variable ,]
  if(max(Exp.tmp$value, na.rm=T) > max(dd.tmp$Mean, na.rm=T)){
    Ymax=max(Exp.tmp$value, na.rm=T)
  }else{
    Ymax=max(dd.tmp$Mean, na.rm=T)
  }
  
  plot(Exp.tmp$DayOfImaging, Exp.tmp$value, type="l", main=paste(tmp$variable, ":", tmp$Key), 
       ylim=c(0, Ymax*1.01))
  lines(dd.tmp$DayOfImaging, dd.tmp$Mean, col="red", lty=2)
}
dev.off()

##These plants were deemed to be outliers based on visual inspection of the graphs.
##Plants that had large spikes in the trend, or had unusually large or very small values
##for multiple time points were dropped. These results may be artifacts of image processing
##or due to disease or injury during the experiment.
BadPlants=c("E1_053409−D",
           "E1_053762−D",
           "E1_054045−D",
           "E1_053864−D",
           "E2_054271−D",
           "E1_053762−D",
           "E2_054390−D",
           "E3_055725−D",
           "E3_055810−D",
           "E3_055825−D",
           "E1_053762−D",
           "E1_054045−D",
           "E1_053409−D",
           "E1_053773−D",
           "E1_053824−D",
           "E1_053864−D",
           "E1_054009−D",
           "E1_053409−D",
           "E1_053409−D",
           "E1_053762−D",
           "E1_054045−D",
           "E2_055036−D",
           "E2_054271−D",
           "E2_054899−D",
           "E2_054446−D",
           "E3_055487−D",
           "E3_055355−D",
           "E3_055926−D",
           "E1_053762−D",
           "E1_053824−D",
           "E1_053782−D",
           "E1_053409−D",
           "E1_053937−D",
           "E1_054045−D",
           "E2_054344−D",
           "E2_054434−D",
           "E2_054557−D",
           "E2_054220−D",
           "E2_054222−D",
           "E2_054271−D",
           "E1_053782−D",
           "E1_054009−D",
           "E1_054045−D",
           "E1_053762−D")

#Get rid of the bad plants
AllExp=AllExp[! AllExp$Key %in% BadPlants ,]
AllExp$Key=NULL
AllExp$variable=as.character(AllExp$variable)
AllExp=AllExp[!AllExp$variable %in% NA ,]

#Convert to wide format
AllExp=dcast(AllExp, Exp + Snapshot.ID.Tag + DayOfImaging + Genotype.ID + 
             Watering.Regime + Replicate + Smarthouse + Lane + Position + 
             Weight.Before + Weight.After + Water.Amount ~ variable, value.var = "value")

##Get NSFTV.IDs for all accessions, drop those without genotypic information
AllExp=merge(AllExp, IDs, by="Genotype.ID", all=F)
AllExp=AllExp[!AllExp$NSFTV.ID %in% "NSFTV_NA" ,]
AllExp$Genotype.ID=NULL

AllExp=merge(AllExp, WUE, by.x=c("Exp", "NSFTV.ID", "Replicate", "DayOfImaging", "Watering.Regime"),
             by.y=c("Exp", "NSFTV.ID", "Rep", "DayOfImaging","Water.Regime"))

write.csv(AllExp, "AllExp_WUE_Morph.csv", row.names = F)
