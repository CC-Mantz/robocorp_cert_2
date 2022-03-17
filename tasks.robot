*** Settings ***
Documentation     Order robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robots
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}PDFs
${IMAGE_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}Screenshots

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${order_file_url}=    Input form Dialogs
    ${orders}=    Download and read CSV file    ${order_file_url}
    FOR    ${order}    IN    @{orders}
        ${order_num}=    Set Variable    ${order}[Order number]
        Close annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait until Keyword Succeeds    3x    2 sec    Submit the order
        ${screenshot}=    Take a screenshot of the robot    ${order_num}
        Create receipt PDF with screenshot    ${order_num}
        Order another robot
    END
    Create ZIP File of Receipts
    [Teardown]    Cleanup

*** Keywords ***
Input form Dialogs
    Add heading    File Location
    Add text input    file    label=File Location
    ${result}=    Run dialog
    [Return]    ${result.file}

Download and read CSV file
    [Arguments]    ${order_file_url}
    Download    ${order_file_url}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Open the robot order website
    ${robotsparesite_url}    Get Secret    robotsparesite_url
    Open Available Browser    ${robotsparesite_url}[URL]
    Maximize Browser Window

Close annoying modal
    Wait Until Element Is Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
    Wait And Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Wait Until Element Is Visible    order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set Variable    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}Receipt_${order_num}.pdf
    Log    End:${pdf}
    Html To Pdf    ${receipt_html}    ${pdf}
    Log    HTML TO PDF:${pdf}
    [Return]    ${pdf}

Create receipt PDF with screenshot
    [Arguments]    ${order_num}
    ${pdf} =    Store the receipt as a PDF file    ${order_num}
    Log    Receipt:${pdf}
    Embed the robot screenshot to the receipt PDF file    order_num=${order_num}    pdf=${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_num}
    Wait Until Element Is Visible    id:robot-preview-image
    ${screenshot}=    Set Variable    ${IMAGE_TEMP_OUTPUT_DIRECTORY}${/}Image_${order_num}.png
    Screenshot    id:robot-preview-image    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_num}    ${pdf}
    ${screenshot}=    Set Variable    ${IMAGE_TEMP_OUTPUT_DIRECTORY}${/}Image_${order_num}.png
    ${screenshot_files}=    Create List    ${screenshot}:align=center
    Log    PDF: ${pdf}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${screenshot_files}    ${pdf}    append=True
    Close Pdf

Order another robot
    Wait Until Element Is Visible    order-another
    Click Button    order-another

Create ZIP File of Receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDF.zip
    Archive Folder With Zip    ${PDF_TEMP_OUTPUT_DIRECTORY}    ${zip_file_name}

Cleanup
    Close Browser
