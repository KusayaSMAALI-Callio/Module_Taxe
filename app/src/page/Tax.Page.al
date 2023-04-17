page 8062644 "CAGTX_Tax"
{

    Caption = 'Tax Setup';
    PageType = Card;
    SourceTable = CAGTX_Tax;

    layout
    {
        area(content)
        {
            group("Général")
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Code field';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field("Calcul Type"; Rec."Calcul Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Calcul Type field';
                }
                group("Default Valorization")
                {
                    Caption = 'Default Valorization';
                    field("Default Rate Type"; Rec."Default Rate Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the value of the Rate Type field';
                    }
                    field("Default Rate Value"; Rec."Default Rate Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the value of the Value field';
                    }
                }
                field("Tax Apply on VAT"; Rec."Tax Apply on VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Apply on VAT Price field';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Allow Invoice Disc. field';
                }
                field("Allow Line Disc."; Rec."Allow Line Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Applied on Amount Incl. Discount field';
                }
                field("Applied Option"; Rec."Applied Option")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Applied Option field';
                }
                field("Posted Option"; Rec."Posted Option")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Posted Option field';
                }
                field("Show Line"; Rec."Show Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Show Line field';
                }
            }
            group(Assignment)
            {
                Caption = 'Assignment';
                field("Sale Account Type"; Rec."Sale Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Sale Account Type field';
                }
                field("Sale Account No."; Rec."Sale Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Sale Account No. field';
                }
                field("Purch. Account Type"; Rec."Purch. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Purchase Account Type field';
                }
                field("Purch. Account No."; Rec."Purch. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Purchase Account No. field';
                }
                field("Service Account Type"; Rec."Service Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Service Account Type field';
                }
                field("Service Account No."; Rec."Service Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Service Account No. field';
                }
            }
            group("Report")
            {
                Caption = 'Reports';
                field("Show on Order Line"; Rec."Show on Order Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Show on Order Line field';
                }
                field("Show on Ship. Line"; Rec."Show on Ship. Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Show on Ship. Line field';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control806185015; Notes)
            {
                ApplicationArea = Basic, Suite;
            }
            systempart(Control806185016; Links)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(TaxAssignment)
            {
                Caption = 'Tax Assignment';
                Image = Allocations;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "CAGTX_Item Tax";
                RunPageLink = "Tax Code" = FIELD(Code);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Assignment action';
                Enabled = IsAppAccessAllowed;
            }
            action(TaxChargedtoThird)
            {
                Caption = 'Tax Assignment To Third Party';
                Image = SalesTax;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "CAGTX_Tax Assgn. to Third Part";
                RunPageLink = "Tax Code" = FIELD(Code);
                ApplicationArea = Basic, Suite;
                ToolTip = 'Executes the Tax Assignment To Third Party action';
                Enabled = IsAppAccessAllowed;
            }
        }
    }
    trigger OnOpenPage()
    var
        AppAccessMgt: Codeunit CAGTX_AppAccessMgt;
    begin
        IsAppAccessAllowed := AppAccessMgt.IsAppAccessAllowed(true);
        CurrPage.Editable(IsAppAccessAllowed);
    end;

    var
        [InDataSet]
        IsAppAccessAllowed: Boolean;
}