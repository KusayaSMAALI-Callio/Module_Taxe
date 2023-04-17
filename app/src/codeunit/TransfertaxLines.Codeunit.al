codeunit 8062610 "CAGTX_Transfer tax Lines"
{

    SingleInstance = true;

    var
        TempLineNoBuffer: Record "Line Number Buffer" temporary;

    procedure InsertLineNumbers(OldLineNo: Integer; NewLineNo: Integer)
    begin
        TempLineNoBuffer."Old Line Number" := OldLineNo;
        TempLineNoBuffer."New Line Number" := NewLineNo;
        TempLineNoBuffer.Insert();
    end;

    procedure GetNewLineNumber(OldLineNo: Integer): Integer
    begin
        if TempLineNoBuffer.Get(OldLineNo) then
            exit(TempLineNoBuffer."New Line Number");

        exit(0);
    end;

    procedure ClearRecLineNo()
    begin
        TempLineNoBuffer.DeleteAll();
    end;


}
