library(shiny)
library(insuranceData)
library(data.table)

data("WorkersComp")
WCdat<-WorkersComp

WCdat<-WCdat[WCdat$PR!=0,]
names(WCdat)<-c("Client","Year","Premium","Loss")

palette(c("#377EB8", "#4DAF4A", "#984EA3","#FF7F00","#E41A1C"))

shinyServer(function(input, output, session) {
    
    # Prepare data for the app
    DT <- data.table(WCdat)
    WCdatByClient<-DT[, lapply(.SD,sum), by=list(Client)]

    WCdatByClient$AvgAnlPremium<-round(WCdatByClient$Premium/7000000,2)
    WCdatByClient$OverallLossRatio<-round((WCdatByClient$Loss/WCdatByClient$Premium)*100,2)
    WCdatByClient$TotalPremium<-round(WCdatByClient$Premium/1000000,2)
    WCdatByClient$TotalLoss<-round(WCdatByClient$Loss/1000000,2)
    
    # Use the selected variable to craete a new data frame
    selectedData <- reactive({
        prmrange<-input$prmrange
        WCdatByClientS<-subset(WCdatByClient,WCdatByClient$AvgAnlPremium<=prmrange)
        selectClients<-WCdatByClientS$Client

        switch(input$ycol,
               "Overall Loss Ratio"={
                   TLRRangeLow<-input$TLRRange[1]
                   TLRRangeHigh<-input$TLRRange[2]
                   
                   WCdatByClientSS<-subset(WCdatByClientS,WCdatByClientS$OverallLossRatio>TLRRangeLow & WCdatByClientS$OverallLossRatio<TLRRangeHigh)
                   WCdatByClientSX<-WCdatByClientSS[,c(AvgAnlPremium)]
                   WCdatByClientSY<-WCdatByClientSS[,c(OverallLossRatio)]
                   WCF<-as.data.frame(cbind(WCdatByClientSX,WCdatByClientSY))
                   names(WCF)<-c("Average Annual Premium (million USD)","Overall Loss Ratio Percentage")
                   WCF
               },
               "Loss Ratio for Selected Period"={
                   YearRangeLow<-input$YearRange[1]
                   YearRangeHigh<-input$YearRange[2]
                   SPLRRangeLow<-input$SPLRRange[1]
                   SPLRRangeHigh<-input$SPLRRange[2]
                   
                   WCdatS1<-subset(WCdat,WCdat$Year>=YearRangeLow & WCdat$Year<=YearRangeHigh)
                   WCdatS<-subset(WCdatS1,WCdatS1$Client %in% selectClients)
                   DT <- data.table(WCdatS)
                   WCdatAgg<-DT[, lapply(.SD,sum), by=list(Client)]
                   WCdatAgg$SLossRatio<-round((WCdatAgg$Loss/WCdatAgg$Premium)*100,2)
                   WCdatAgg$AvgAnlPremium<-WCdatByClientS[match(WCdatAgg$Client, WCdatByClientS$Client),AvgAnlPremium]
                   WCdatAggSub<-subset(WCdatAgg,WCdatAgg$SLossRatio>SPLRRangeLow & WCdatAgg$SLossRatio<SPLRRangeHigh)
                   
                   WCX<-WCdatAggSub[,c(AvgAnlPremium)]
                   WCY<-WCdatAggSub[,c(SLossRatio)]
                   
                   WCF<-as.data.frame(cbind(WCX,WCY))
                   names(WCF)<-c("Average Annual Premium (million USD)","Loss Ratio Percentage for Selected Period")
                   WCF    
                },
               "Total Loss"={
               TotalLossRangeLow<-input$TotalLossRange[1]
               TotalLossRangeHigh<-input$TotalLossRange[2]
               
               WCdatByClientSS<-subset(WCdatByClientS,WCdatByClientS$TotalLoss>TotalLossRangeLow & WCdatByClientS$TotalLoss<TotalLossRangeHigh)
               WCdatByClientSX<-WCdatByClientSS[,c(AvgAnlPremium)]
               WCdatByClientSY<-WCdatByClientSS[,c(TotalLoss)]
               WCF<-as.data.frame(cbind(WCdatByClientSX,WCdatByClientSY))
               names(WCF)<-c("Average Annual Premium (million USD)","Total Loss (million USD)")
               WCF     
           }
        )
        
        })
    
    # Get k-means for the user selected number of clusters
    clusters <- reactive({
        kmeans(selectedData(), input$clusters)
    })
    
    # Plot the data points colored by k-means clusters. Also show centers of clusters 
    output$plot1 <- renderPlot({
        par(mar = c(5.1, 4.1, 0, 1))
        plot(selectedData(),
             col = clusters()$cluster,
             pch = 20, cex = 3)
        points(clusters()$centers, pch = 4, cex = 3, lwd = 4)
    })
    
    # Generate a summary of the selected data
    
    output$plot2 <- renderPlot({
        x <- WCdatByClient$AvgAnlPremium  
        bins <- seq(min(x), max(x), length.out = 20)
        
        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'brown', border = 'white',
             xlab="Average Annual Premium (million USD)",
             main="Histogram of Average Annual Premium for all Clients")
    })   
         y <- WCdatByClient$OverallLossRatio  
        bins <- seq(min(y), max(y), length.out = 20)
   
    output$plot3 <- renderPlot({     
        
        # draw the histogram with the specified number of bins
        hist(y, breaks = bins, col = 'orange', border = 'white',
             xlab="Overall Loss Ratio Percentage",
             main="Histogram of Overall Loss Ratio Percentage for all Clients")
    })
    
    output$summary <- renderPrint({
        summary(selectedData())
            })
        
    # Display the selected table in the form of a table
    output$table <- renderTable({
        data.frame(selectedData())
    })
})