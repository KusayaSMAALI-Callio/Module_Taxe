pageextension 8062632 "CAGTX_Service Invoice Subform" extends "Service Invoice Subform"
{
    layout
    {
        addafter("ShortcutDimCode[8]")
        {
            field("CAGTX_Tax Amount"; Rec."CAGTX_Tax Amount")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Tax Amount field';
            }
        }
    }
}

