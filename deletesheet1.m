function [] = deletesheet1(excelFileName)   

% excelFileName = sprintf('%s %gblock.xlsx',inputname(1),number_blocks);
    excelFilePath = pwd; % Current working directory.
    sheetName = 'Sheet'; % EN: Sheet, DE: Tabelle, etc. (Lang. dependent)

    % Open Excel file.
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(fullfile(excelFilePath, excelFileName)); % Full path is necessary!

    % Delete sheets.
    try
    % Throws an error if the sheets do not exist.
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    objExcel.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    catch
    ; % Do nothing.
    end

    % Save, close and clean up.
    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;    
end
