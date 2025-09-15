# ====================================================
# Shiny App: R Error Helper with OpenAI
# Author: [Your Name / Book Title]
# Note: Each user must provide their own OpenAI API key
# ====================================================

# Install packages if not already installed
required_packages <- c("shiny", "httr", "jsonlite")
installed <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!(pkg %in% installed)) install.packages(pkg)
}
library(shiny)
library(httr)
library(jsonlite)

# =========================================
# Helper function: talk to OpenAI API
# =========================================
get_correction <- function(user_code, user_error, user_key) {
  
  # Define the system + user prompts
  system_msg <- list(
    role = "system",
    content = "You are an R coding assistant. A beginner biologist has pasted their R code and an error message. 
    Your job: find the bug, fix the code, and explain clearly in plain English what was wrong and why your correction works."
  )
  
  user_msg <- list(
    role = "user",
    content = paste0("Here is my R code:\n\n", user_code, 
                     "\n\nHere is the error I got:\n\n", user_error, 
                     "\n\nPlease correct it and explain step by step.")
  )
  
  # Send request
  res <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", user_key)),
    content_type_json(),
    body = toJSON(list(
      model = "gpt-4o-mini",  # fast, cheaper model
      messages = list(system_msg, user_msg),
      temperature = 0
    ), auto_unbox = TRUE)
  )
  
  # Handle errors
  if (status_code(res) != 200) {
    return(paste("⚠️ API Error:", status_code(res), content(res, "text")))
  }
  
  # Extract reply
  reply <- content(res, as = "parsed", type = "application/json")
  return(reply$choices[[1]]$message$content)
}

# =========================================
# Shiny UI
# =========================================
ui <- fluidPage(
  titlePanel("🧪 R Error Helper (DIY Version)"),
  sidebarLayout(
    sidebarPanel(
      passwordInput("apikey", "Enter your OpenAI API Key:", placeholder = "sk-..."),
      textAreaInput("code", "Paste your R code here:", rows = 10),
      textAreaInput("error", "Paste the error message here:", rows = 5),
      actionButton("fix", "Get Help"),
      width = 4
    ),
    mainPanel(
      h4("Corrected Code & Explanation:"),
      verbatimTextOutput("result"),
      width = 8
    )
  )
)

# =========================================
# Shiny Server
# =========================================
server <- function(input, output, session) {
  
  observeEvent(input$fix, {
    req(input$apikey, input$code, input$error)
    
    output$result <- renderText({
      get_correction(input$code, input$error, input$apikey)
    })
  })
}

# =========================================
# Run the app
# =========================================
shinyApp(ui = ui, server = server)
