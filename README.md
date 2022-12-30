# Mapping Mariah Carey's <i>All I Want for Christmas Is You</i>
An interactive animated choropleth map tracking the popularity of Mariah Carey's "All I Want For Christmas is You" on Spotify from November to December 2020 across the world. You can move around the map and hover over each country for more information. It is also accompanied by an animated histogram to visualise how the distribution of chart ranks changes across time. This visualisation was created as part of a UCL Data Visualisation Society workshop I led on creating interactive maps.

Here's a screen recording of the animated map and the accompanying histogram. You can explore the interactive map and histogram <a href = "https://brendonkoh-portfolio.netlify.app/projects/how-popular-is-all-i-want-for-christmas-is-you/#visualisation-and-brief-analysis" target = "_blank">here</a>.



https://user-images.githubusercontent.com/120264123/210016650-73b2cfd5-a4bd-4cc1-8033-f2aa5b78b855.mp4






The Spotify Chart data used was obtained from <a href = "https://www.kaggle.com/datasets/dhruvildave/spotify-charts?select=charts.csv">Kaggle</a> while the ISO-3166 country codes used to plot the map was obtained from the <a href = "https://www.iso.org/iso-3166-country-codes.html">ISO website</a> (I have uploaded a .csv file that contains all the country codes). The map was created in R using the 'plotly' package.

A complete explanation of the data cleaning and visualisation process can be found on my <a href = "https://brendonkoh-portfolio.netlify.app/projects/how-popular-is-all-i-want-for-christmas-is-you/" target = "_blank">website</a>.
