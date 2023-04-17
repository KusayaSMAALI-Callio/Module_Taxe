pageextension 8062643 "CAGTX_Purchase Return Order SF" extends "Purchase Return Order Subform"
{

    layout
    {

        modify(Control1)
        {
            IndentationColumn = IndentTax_G;
            IndentationControls = Description;
        }

    }

    var
        [InDataSet]
        IndentTax_G: Integer;

    trigger OnAfterGetRecord()
    begin
        SetIndentTaxLine();
    end;

    LOCAL Procedure SetIndentTaxLine()
    begin
        IndentTax_G := 0;
        IF Rec."CAGTX_Origin Tax Line" <> 0 THEN
            IndentTax_G := 1;
    end;
}

