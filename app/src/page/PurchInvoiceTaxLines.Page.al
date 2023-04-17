page 8062607 "CAGTX_Purch Invoice Tax Lines"
{

    Caption = 'Tax Lines';
    PageType = List;
    SourceTable = "Purch. Inv. Line";
    SourceTableView = SORTING("Document No.", "Line No.")
                      ORDER(Ascending)
                      WHERE("CAGTX_Tax Line" = CONST(true));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Buy-from Vendor No. field';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Document No. field';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Line No. field';
                }
                field("CAGTX_Tax Line"; Rec."CAGTX_Tax Line")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Tax Line field';
                }
                field("CAGTX_Tax Code"; Rec."CAGTX_Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Tax Code field';
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Quantity field';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Line Discount % field';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Line Discount Amount field';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount field';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount Including VAT field';
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Allow Invoice Disc. field';
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Inv. Discount Amount field';
                }
                field("CAGTX_Origin Tax Line"; Rec."CAGTX_Origin Tax Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the CAGTX_Origin Tax Line field';
                }
            }
        }
    }

    actions
    {
    }
}