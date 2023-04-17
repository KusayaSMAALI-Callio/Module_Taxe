pageextension 8062639 "CAGTX_Sales Quote Subform" extends "Sales Quote Subform"
{

    layout
    {
        modify(Control1)
        {
            IndentationColumn = IndentTax_G;
            IndentationControls = Description;
        }

        addafter(ShortcutDimCode8)
        {
            field("CAGTX_Tax Code"; Rec."CAGTX_Tax Code")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Tax Code field';
            }
            field("CAGTX_Tax Line"; Rec."CAGTX_Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Tax Line field';
            }
            field("CAGTX_Origin Tax Line"; Rec."CAGTX_Origin Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Origin Tax Line field';
            }
            field("CAGTX_Hide Tax Line"; Rec."CAGTX_Hide Tax Line")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Hide Tax Line field';
            }
            field("CAGTX_Tax Amount"; Rec."CAGTX_Tax Amount")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Tax Amount field';
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

