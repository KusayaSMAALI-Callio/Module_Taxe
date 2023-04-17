pageextension 8062624 "CAGTX_Purchase Lines" extends "Purchase Lines"
{
    layout
    {
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
            field("CAGTX_Tax Amount"; Rec."CAGTX_Tax Amount")
            {
                Visible = false;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Tax Amount';
            }
        }
    }
}