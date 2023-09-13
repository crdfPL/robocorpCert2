*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    OperatingSystem
Library    RPA.Desktop
Library    RPA.PDF
Library    RPA.Archive
*** Variables ***
${screenshot_dir}=    ${OUTPUT_DIR}${/}screenshots
${receipt_dir}=    ${OUTPUT_DIR}${/}receipts
*** Tasks ***
Test Task
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Fill and submit the form for one order    ${order}
        Preview robot
        Wait Until Keyword Succeeds    10x    500ms    Submit order
        Create PDF receipt    ${order}[Order number]
        Order new robot
    END
    Create ZIP file of all receipts
    [Teardown]    Close the Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Log    Done.

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Fill and submit the form for one order
    [Arguments]    ${order}
    Close cookies
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    

Preview robot
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    
Submit order
    Wait And Click Button     //*[@id="order"]
    Wait Until Element Is Visible    //*[@id="order-completion"]
    Wait Until Element Is Visible    //*[@id="order-another"]

Order new robot
    Wait And Click Button     //*[@id="order-another"]   
Create PDF receipt
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    //*[@id="receipt"]    timeout=10
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]    timeout=10
    ${pdf}=    Store order receipt as PDF file    ${order_number}
    ${screenshot}=    Take a screenshot of the robot    ${order_number}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}

Store order receipt as PDF file
    [Arguments]    ${order_number}
    Set Local Variable    ${file_path}    ${receipt_dir}${/}${order_number}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${file_path} 
    [Return]    ${file_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Set Local Variable    ${file_path}    ${screenshot_dir}${/}${order_number}.PNG
    Screenshot    locator=//*[@id="robot-preview-image"]    filename=${file_path}
    [Return]    ${file_path}
       
Embed the robot screenshot to the receipt PDF file 
    [Arguments]    ${screenshot}    ${pdf}
    ${screenshots}=    Create List    ${screenshot}:align=center
    Add Files To Pdf     ${screenshots}   ${pdf}    append=${True}

Create ZIP file of all receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip    ${receipt_dir}    ${zip_file_name}

Close cookies
    Wait And Click Button    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]    

Close the Browser
    Close Browser
