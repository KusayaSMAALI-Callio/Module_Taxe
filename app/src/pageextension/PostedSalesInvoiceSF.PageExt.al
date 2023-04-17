pageextension 8062608 "CAGTX_Posted Sales Invoice SF" extends "Posted Sales Invoice Subform"
{

    actions
    {
        addlast("&Line")
        {
            action("CAGTX_Tax Lines")
            {
                Caption = 'Tax Lines';
                Image = ExpandDepositLine;
                RunObject = Page "CAGTX_Sales Invoice Tax Lines";
                RunPageLink = "Document No." = FIELD("Document No."),
                              "CAGTX_Origin Tax Line" = FIELD("Line No.");
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Lines action';
            }
        }
    }
}

