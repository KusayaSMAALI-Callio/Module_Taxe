pageextension 8062642 "CAGTX_Purchase Return Order" extends "Purchase Return Order"
{
    layout
    {
        addafter("Pay-to")
        {
            field("CAGTX_Disable Tax Calculation"; Rec."CAGTX_Disable Tax Calculation")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the value of the CAGTX_Disable Tax Calculation field';
            }
        }
    }
}

