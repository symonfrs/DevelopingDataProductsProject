#Worker's Compensation Insurance Client Segmentation App

shinyUI(pageWithSidebar(
    headerPanel('Workers Compensation Insurance Client Segmentation'),
    sidebarPanel(
        
        sliderInput('prmrange', "Client Annual Premium Range (million USD)", 
                    min=0,max=5000,value=2000,step = 1),
        
        selectInput('ycol', "Client Specific Loss Attribute", 
                    c("Overall Loss Ratio", "Loss Ratio for Selected Period","Total Loss"),
                    selected="Overall Loss Ratio"),
        
        conditionalPanel(condition="input.ycol=='Loss Ratio for Selected Period'",
                         sliderInput("YearRange","Select Year Range:",
                                     min=1,max=7,value=c(5,7))),
        conditionalPanel(condition="input.ycol=='Total Loss'",
                         sliderInput("TotalLossRange","Select Loss Range (million USD):",
                                     min=0,max=115,value=c(10,90),step = 1)),
        conditionalPanel(condition="input.ycol=='Overall Loss Ratio'",
                         sliderInput("TLRRange","Select Loss Ratio Percentage Range:",
                                     min=0,max=12,value=c(0,12),step=0.1)),
        conditionalPanel(condition="input.ycol=='Loss Ratio for Selected Period'",
                         sliderInput("SPLRRange","Select Loss Ratio Percentage Range:",
                                     min=0,max=12,value=c(0,12),step=0.1)),

        numericInput('clusters', 'Number of k-means clusters', 5,
                     min = 1, max = 5)
    ),
    mainPanel(
        tabsetPanel(type = "tabs", 
                    tabPanel("Segmentation Plot", plotOutput("plot1")), 
                    tabPanel("Data Summary", verbatimTextOutput("summary")),
                    tabPanel("Data Table", tableOutput("table")),
                    tabPanel("Histograms", plotOutput("plot2"),plotOutput("plot3"))
    )
)))

