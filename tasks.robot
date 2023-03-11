*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${blnConfirmationExists}    ${False}
${X_Path}                   input[@id='id-body-1']    # Declare
${Dyn_X_Path}
${ind}                      3


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Log    ====>>> Started.
    Create Directory    ${OUTPUT_DIR}${/}PDFs
    Create Directory    ${OUTPUT_DIR}${/}Temp
    Download the Excel file
    Open webPage
    Loop through csv data and send parts lists
    Create ZIP package from PDF files
    Cleanup temporary PDF directory
    Log    ====>>> Done.


*** Keywords ***
Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Open webPage
    Open Available Browser

Go to URL Dismiss PopUp
    Go To    https://robotsparebinindustries.com/#/robot-order

    ${danger}    Is Element Visible    class:btn.btn-danger
    IF    ${danger} == ${True}    Wait And Click Button    class:btn.btn-danger

Submit Order Form
    [Arguments]    ${singleRobotPartsList}

    WHILE    ${blnConfirmationExists} == $False    limit=5
        Go to URL Dismiss PopUp

        Click Element    name:head

        Select From List By Index    name:head    ${singleRobotPartsList}[Head]

        ${ind}    Set Variable    ${singleRobotPartsList}[Body]
        Click Element    xpath://input[@id='id-body-${ind}']

        Input Text    css:[placeholder='Enter the part number for the legs']    ${singleRobotPartsList}[Legs]

        Input Text    xpath://input[@id='address']    ${singleRobotPartsList}[Address]

        Click Button    xpath://button[@id='preview']

        Click Button    xpath://button[@id='order']

        Sleep    2

        ${blnConfirmationExists}    Is Element Visible    xpath://div[@id='order-completion']
    END

    IF    $blnConfirmationExists == ${True}
        Log    Success
        #Screenshot    xpath://div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}sales_summary.png
        ${reciept_html}    Get Element Attribute    xpath://div[@id='order-completion']    outerHTML
        ${fileName_png}    Set Variable    ${singleRobotPartsList}[Order number].png
        ${fileName_pdf}    Set Variable    ${singleRobotPartsList}[Order number].Pdf
        ${screenshot}    Screenshot    xpath://div[@id='robot-preview-image']    ${fileName_png}
        Html To Pdf    ${reciept_html}    ${OUTPUT_DIR}${/}Temp${/}${fileName_pdf}
        ${files}    Create List    ${fileName_png}
        Add Files To PDF    ${files}    ${OUTPUT_DIR}${/}Temp${/}${fileName_pdf}    ${True}

        #Open Pdf
    ELSE
        Log    Failure
    END

Loop through csv data and send parts lists
    ${robot_parts}    Read table from CSV    orders.csv    header=true    dialect=excel
    # For each row in csv file
    FOR    ${singleRobotPartsList}    IN    @{robot_parts}
        Log    ${singleRobotPartsList}
        Submit Order Form    ${singleRobotPartsList}
    END

Create ZIP package from PDF files
    ${zip_file_name}    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}Temp
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${OUTPUT_DIR}${/}Temp    True
