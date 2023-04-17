pageextension 8062634 "CAGTX_Service Credit Memo SF" extends "Service Credit Memo Subform"
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

