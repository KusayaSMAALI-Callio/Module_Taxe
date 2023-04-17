pageextension 8062627 "CAGTX_Get Receipt Lines" extends "Get Receipt Lines"
{
    layout
    {
        addafter("Qty. Rcd. Not Invoiced")
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
        }
    }
}

