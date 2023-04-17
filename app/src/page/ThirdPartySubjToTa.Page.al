page 8062643 "CAGTX_Third Party Subj. To Ta"
{

    Caption = 'Third Party Subject To Tax';
    Editable = false;
    PageType = NavigatePage;
    SourceTable = "CAGTX_Customer Subject To Tax";

    layout
    {
        area(content)
        {
            repeater(Control1000000001)
            {
                ShowCaption = false;
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code field';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Type field';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field';
                }
                field("Invoiced Tax"; Rec."Invoiced Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Invoiced Tax field';
                }
            }
        }
    }

    actions
    {
    }
}