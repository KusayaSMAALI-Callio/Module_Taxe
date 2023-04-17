pageextension 8062606 "CAGTX_Copy Item" extends "Copy Item"
{
    layout
    {
        addafter(Purchase)
        {
            group("CAGTX_Taxes")
            {
                Caption = 'Taxes';

                field("CAGTX_IncludeTaxes"; Rec."CAGTX_IncludeTaxes")
                {
                    Caption = 'Taxes';
                    ToolTip = 'Define if Taxes must be copy';
                    ApplicationArea = all;
                }
            }
        }
    }
}