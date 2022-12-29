library(tidyverse) #for data cleaning
library(lubridate) #for manipulating dates
library(plotly) #for plotting our map
library(extrafont) #for additional font options
library(htmlwidgets) #to export our final product


#Loading in spotify chart data from kaggle
chartdata <- read.csv("charts.csv")

#Inspecting what we are working with
dim(chartdata)
head(chartdata)

##--- Data cleaning ---##

#Filtering for "All I Want for Christmas Is You" and selecting relevant rows for plot
mariah <- chartdata %>% filter(title == "All I Want for Christmas Is You", artist == "Mariah Carey", chart == "top200", region != "Global") %>% select("rank", "date", "region", "streams")
#Formatting 'date' column as dates
mariah$date <- as.Date(mariah$date, format = "%Y-%m-%d")
#Subsetting for Dec 2020
mariah <- mariah %>% filter(date >= '2020-11-01', date < '2021-01-01')


#Checking to see if there are any regions that we have data for that didn't have All I Want for Christmas Is You break the Top 200 Charts in Nov-Dec 2020
setdiff(unique(chartdata$region), unique(mariah$region))

#Let's see what's going on with S.Korea and Andorra
skorea <- chartdata %>% filter(region == "South Korea")
head(skorea)
skorea %>% filter(as.Date(date, format = "%Y-%m-%d") < "2021-01-01") # no results

#Andorra
andorra <- chartdata %>% filter(region == "Andorra")
head(andorra)
andorra %>% filter(chart == "top200") #no results

#S. Korea doesn't have data prior to 2021. Andorra only has data for Viral 50 Charts, not Top 200.
#This means that for every country spotify had top200 data for in nov-dec 2020, mariah appeared on the top 200 charts at least once. In other words, any missing region from the dataset is because there was no chart data collected (or scraped) for these areas.



##---Merging country code data for plotting---##
#To ensure accuracy, I am using iso3166 country codes for plotting instead of region names

#reading in country code data
iso <- read.csv("iso3166_29dec2022.csv")
head(iso, n = 5)

#Cleaning up iso3166 data
iso_clean <- iso %>% select("English.short.name", "Alpha.3.code")
colnames(iso_clean) <- c("region", "iso3")

#Since we'll be merging by region names, checking whether region names are different
setdiff(unique(mariah$region), unique(iso_clean$region))

#Recodes all the names in the iso data with the names in the spotify data. For simplicity's sake, spotify region names are used instead.
#The only exception where we're using the iso3166 name is for Türkiye to respect the name change
iso_clean <- iso_clean %>% 
  dplyr::mutate(region = recode(region, "Netherlands(the)" = "Netherlands",
                                "Czechia" = "Czech Republic",
                                "Dominican Republic(the)" = "Dominican Republic",
                                "United Kingdom of Great Britain and Northern Ireland (the)" = "United Kingdom",
                                "United States of America (the)" = "United States",
                                "Philippines (the)" = "Philippines", 
                                "Russian Federation (the)" = "Russia", 
                                "Taiwan (Province of China)" = "Taiwan", 
                                "United Arab Emirates (the)" = "United Arab Emirates", 
                                "Viet Nam" = "Vietnam", 
                                "Bolivia (Plurinational State of)" = "Bolivia",
                                "T\xfcrkiye" = "Türkiye")) #formatting of Türkiye was lost somewhere, so I'm recoding it

#Recoding Turkey's name in the spotify data 
mariah <- mariah %>% dplyr::mutate(region = recode(region, "Turkey" = "Türkiye"))

#Merging
mariah_2020 <- left_join(mariah, iso_clean, by = "region")



##---Creating breaks for plotting---##

#renaming to "actual.rank" as we will be creating a "Rank" variable later on
colnames(mariah_2020)[colnames(mariah_2020) == "rank"] <- "actual.rank"

#Creating breaks
mariah_2020$breaks <- cut(mariah_2020$actual.rank, breaks = c(0, 1, 5, 10, 20, 50, 100, 200))
levels(mariah_2020$breaks) <- c("1", "2-5", "6-10", "11-20", "21-50", "51-100", "101-200", "<200")
#Reversing factors. Rank 1 should have the highest value when plotting the map
mariah_2020$breaks <- fct_rev(mariah_2020$breaks)

#Converting columns into characters to enable filling in of values
mariah_2020$actual.rank <- as.character(mariah_2020$actual.rank)
mariah_2020$streams <- as.character(mariah_2020$streams)

#As observations are only recorded when the song enters the Top 200 Chart, the plot can't differentiate between instances when the song wasn't in the top 200 chart and cases where there is simply no data about the region. Both are missing from the data we have.
#We can fix that by filling in values based on the regions we have data on. For dates when a region has no data recorded, their rank is coded as "Not in the Top 200 Charts" rather than being missing from the data. This is because the missingness is caused by the song not being in the top 200 chart rather than there being no data collected for the region.
mariah.complete <- mariah_2020 %>% 
  complete(date, nesting(region, iso3), fill = list(actual.rank = "<i>Not in the Top 200 chart</i>", 
                                                    streams = "<i>Not in the Top 200 chart</i>", 
                                                    breaks = "<200")) 

#Creating a new column of the numeric values for each category. This will be used for the plot
mariah.complete$Rank <- as.numeric(mariah.complete$breaks)

#Converting date column back to character. Plotly can't take in date data
mariah.complete$Date <- as.character(mariah.complete$date)



##---Customising plot options---##

#Sets what information is shown when hovering
mariah.complete$hover <- with(mariah.complete,paste('<b>',region,'</b>','<br>',
                                                    'Chart Rank:', actual.rank, '<br>',
                                                    'Daily Streams:', streams))

#Customises hover layout
hover.layout <- list(
  bgcolor = "#126c50",                     
  bordercolor = "transparent",             
  font = list(size = 10,                  
              color = "white")
)

#Creating tick positions
tick.positions <- vector(length = 8)
for(i in 1:8){
  tick.positions[i] <- (7/8)*0.5 + (7/8)*(i-1) + 1
}

#Specify map projections and options
g <- list(
  framecolor = "#b19f98", 
  projection = list(type = "Mercator"), 
  bgcolor = "transparent", 
  coastlinecolor = "#b19f98", 
  coastlinewidth = 0.5,       
  showland = T,
  landcolor = "#faf6ed",
  showocean = T,
  oceancolor = "#faf6ed")

#Specifies the boundary characteristics of countries that are inside our data
l <- list(line = list(color = "#b19f98", width = 0.5))

#Customises date value layout
date.layout <- list(font = list(size = 20,
                                color = "#126c50"))

##---Creating the interactive map---##
mariah.map <- plot_geo(mariah.complete,            
                       frame = ~Date,            
                       locations = ~iso3,         
                       z = ~Rank,
                       zmin = 1,       
                       zmax = 8,
                       color = ~Rank,      
                       colorscale = "Reds",
                       text = ~hover,
                       hoverinfo = 'text',
                       showlegend = F,
                       marker = l) %>%       
  
  layout(geo = g, 
         margin = list(t = 50),
         paper_bgcolor = "#faf5e7",
         font = list(color = "#b42d1e",
                     family = "Roboto Condensed"),  
         title = "<b>Popularity of 'All I Want for Christmas Is You' on Spotify across the 2020 festive season</b><br><i>Source: <a href = 'https://www.kaggle.com/datasets/dhruvildave/spotify-charts?select=charts.csv'>Spotify Top 200 Charts</a></i>") %>%  
  
  style(hoverlabel = hover.layout)  %>%
  
  colorbar(tickvals = tick.positions, 
           ticktext = levels(mariah.complete$breaks),
           tickfont = list(size = 13),
           tickcolor = "#b42d1e",
           outlinecolor = "transparent") %>%
  
  animation_slider(font = list(color = "#126c50"),  
                   currentvalue = date.layout,   
                   bgcolor = "#126c50",             
                   tickcolor = "#126c50") %>%
  
  animation_button(font = list(text = "<b>Play</b>",
                               color = "#126c50",
                               size = 14))

mariah.map

#Exorting the plotly map. partial_bundle() to reduce file size
saveWidget(partial_bundle(mariah.map), file = "christmasvisualisation.html", selfcontained = T)

##---Creating an accompanying animated histogram to track distribution of chart ranks across time---##
mariah.hist <- plot_ly(mariah.complete,
                       x = ~breaks,
                       type = "histogram",
                       frame = ~Date,
                       showlegend = F,
                       texttemplate = "<b>%{y}</b>",     #to add frequency count above bars
                       textposition = "outside",
                       marker = list(color = "#b42d1e")) %>% #to specify color of bars
  
  layout(paper_bgcolor = "#faf5e7",  #to specify color of paper
         plot_bgcolor = "#faf5e7",   #to specify color of plot background
         margin = list(t = 50),      #to add top margins to the plot  
         font = list(family = "Roboto Condensed",   #controls font family and color
                     color = "#b42d1e"),
         title = "<b>Distribution of Spotify Chart Ranks for 'All I Want for Christmas Is You' across 67 regions</b><br><i>Source: <a href = 'https://www.kaggle.com/datasets/dhruvildave/spotify-charts?select=charts.csv'>Spotify Top 200 Charts</a></i>",
         xaxis = list(title = "",
                      range = c(-1, 8)),     #removes x-axis title and sets zoom window of the plot
         yaxis = list(range = c(0, 59))) %>%  
  
  animation_slider(font = list(color = "#126c50"),  #controls animation slider visuals
                   currentvalue = date.layout,   
                   bgcolor = "#126c50",             
                   tickcolor = "#126c50") %>%
  
  animation_button(font = list(text = "<b>Play</b>", #controls animation button visuals
                               size = 14,
                               color = "#126c50"))

mariah.hist

#Exporting histogram
saveWidget(partial_bundle(mariah.hist), "hist.html")


