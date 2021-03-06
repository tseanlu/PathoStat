shiny_panel_biomarker <- fluidPage(

    tabsetPanel(
        tabPanel("Classification Model",
                 br(),
                 sidebarLayout(
                     sidebarPanel(
                         br(),
                         selectizeInput('taxl_biomarker', 'Taxonomy Level', choices = tax.name,
                                        selected='genus'),
                         selectInput("select_target_condition_biomarker", "Select Target Condition:",
                                     covariates.two.levels),
                         numericInput("num.cv.nfolds", "Number of CV nfolds", value = 3, max = 20),
                         selectInput("select_covariate_condition_biomarker", "Select Covarites Conditions:",
                                     covariates, multiple = TRUE),
                         selectInput("select_model_biomarker", "Select Model", c("Lasso Logistic Regression", "Ensemble Model")),
                         actionButton("goButtonBiomarker", "Run!"),
                         width=3
                     ),
                     mainPanel(
                         tabsetPanel(
                             tabPanel("Feature selection",
                                      br(),
                            verbatimTextOutput("featureSelectionTmp"))
                         ), width=9
                     )
                 )
        )
    )

)
