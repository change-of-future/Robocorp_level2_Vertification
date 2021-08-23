# +
*** Settings ***
Documentation   
...               Saves the Order CSV file from web
...               Orders robots from RobotSpareBin Industries Inc for each order in CSV
...               Saves the order HTML receipt as a PDF file
...               Saves the screenshot of the ordered robot
...               Embeds the screenshot of the robot to the PDF receipt
...               Creates ZIP archive of the receipts
...               Deletes the Screenshots

Library         RPA.Robocloud.Secrets
Library         RPA.Browser
Library         RPA.Tables
Library         RPA.HTTP
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         Dialogs
Library         RPA.FileSystem
# -


*** Keywords ***
Run dialog


*** Keywords ***
Input form dialog
    ${csv_url}=  Get Value From User  Enter the CSV file URL
    Download order file  ${csv_url}

*** Keywords ***
Accessing URL from vault
   ${secret}=  Get Secret  orderurl
    #${secret}= Get Secret  order_url
    #log  "order_url"
    
    Log    ${secret}[url]

*** Keywords ***
Download order file
    [Arguments]    ${csv_url}
    #Download  overwrite=True    url=https://robotsparebinindustries.com/orders.csv
    Download  overwrite=True    url=${csv_url}
    ${orders}=    Read table from CSV  orders.csv
    Log   Found columns: ${orders.columns}

    FOR    ${order}    IN    @{orders}
        Log  Processing ${order}
       # Wait Until Keyword Succeeds    2x    1 sec  Fill And Submit The Form For One Order    ${order}
        Run Keyword And Continue On Failure  Fill And Submit The Form For One Order    ${order}
        
    END

*** Keywords ***
Open The Order Website
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser    ${secret}[url]
    Maximize Browser Window
    Download order file
    #[Teardown]    Close Browser

*** Keywords ***
handling order button error

    Click Button  Order
    
    Wait Until Element Is Visible    id:receipt
    Wait Until Element Is Visible    id:robot-preview-image

*** Keywords ***
Fill And Submit The Form For One Order
    [Arguments]    ${order}
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Click Button    OK
    Select From List By Value    head   ${order}[Head]
    Select Radio Button    body  ${order}[Body]
    Input Text  class:form-control  ${order}[Legs]
    Input Text  address  ${order}[Address]
    Click Button  Preview
   # Wait Until Keyword Succeeds    5x    1 sec  Click Button  Order
    #Run Keyword And Continue On Failure  
    Wait Until Keyword Succeeds    4x    3 sec  handling order button error
    #Click Button  Order
    
    #Wait Until Element Is Visible    id:receipt
    #Wait Until Element Is Visible    id:robot-preview-image
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}${order}[Order number].pdf
   # Press key    page_down
   # Press key    up
   # Press key    up
   
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order}[Order number].png
    #${files}=    Create List
    #...         ${receipt_html}
    #...         ${CURDIR}${/}output${/}${order}[Order number].pdf
    #...         ${CURDIR}${/}output${/}${order}[Order number].png
    Add Watermark Image To Pdf  ${CURDIR}${/}output${/}${order}[Order number].png  ${CURDIR}${/}output${/}${order}[Order number].pdf  ${CURDIR}${/}output${/}${order}[Order number].pdf 
    #Add Files To PDF   ${files}  ${CURDIR}${/}output${/}${order}[Order number].pdf 
    #Delete  ${CURDIR}${/}output${/}${order}[Order number].png
    #Click Button  Order another robot
    Close Pdf  ${CURDIR}${/}output${/}${order}[Order number].pdf 
    #Add Files To PDF   ${files}  ${CURDIR}${/}output${/}${order}[Order number].pdf 
    Remove File  ${CURDIR}${/}output${/}${order}[Order number].png 
    
    Log  Processed ${order}
    [Teardown]  Close Browser
    #Close Browser


*** Tasks ***
open
    #Open The Order Website
    #Download order file
    Input form dialog
    Accessing URL from vault
    #Download order file
    Archive Folder With Zip  ${CURDIR}${/}output  ${CURDIR}${/}output${/}Orders.zip  include=*.pdf
    #Empty Directory  ${CURDIR}${/}output
    #Move File  ${CURDIR}${/}Orders.zip  ${CURDIR}${/}output${/}Orders.zip  overwrite=True


