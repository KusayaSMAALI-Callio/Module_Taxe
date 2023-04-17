pageextension 8062620 "CAGTX_Sales Invoice Subform" extends "Sales Invoice Subform"
{

    layout
    {

        modify(Control1)
        {
            IndentationColumn = IndentTax_G;
            IndentationControls = Description;
        }

        addlast(Control1)
        {
            field("CAGTX_Tax Code"; Rec."CAGTX_Tax Code")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Tax Code';
            }
            field("CAGTX_Tax Line"; Rec."CAGTX_Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Tax Line';
            }
            field("CAGTX_Origin Tax Line"; Rec."CAGTX_Origin Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Origin Tax Line';
            }
            field("CAGTX_Hide Tax Line"; Rec."CAGTX_Hide Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Hide Tax Line';
            }
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

