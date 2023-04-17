page 8062612 "CAGTX_Service Doc. Tax Detail"
{

    Caption = 'CMB- Service Doc. Tax Detail';
    PageType = List;
    SourceTable = "CAGTX_Service Doc. Tax Detail";

    layout
    {
        area(content)
        {
            group(Control806185003)
            {
                Editable = false;
                ShowCaption = false;
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
                    DrillDown = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Description field';
                }
                field(Quantity; Rec.Quantity)
                {
                    DrillDown = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Quantity field';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount field';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    DrillDown = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Line Discount Amount field';
                }
            }
            repeater(Group)
            {
                field("Calcul Type"; Rec."Calcul Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Calcul Type field';
                }
                field("Tax Code"; Rec."Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Code field';
                }
                field("Tax No."; Rec."Tax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax No. field';
                }
                field("Tax Description"; Rec."Tax Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Tax Description field';
                }
                field("Quantity Tax Line"; Rec."Quantity Tax Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Quantity Tax Line field';
                }
                field("Amount Tax Line"; Rec."Amount Tax Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Amount Tax Line field';
                }
                field("Base Quantity Tax"; Rec."Base Quantity Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Base Quantity Tax Line field';
                }
                field("Rate value"; Rec."Rate value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Rate Value field';
                }
                field("Rate Type"; Rec."Rate Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Rate Type  field';
                }
                field("Base Amount Tax"; Rec."Base Amount Tax")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Base Amount Tax Line field';
                }
            }
        }
    }

    actions
    {
    }
}