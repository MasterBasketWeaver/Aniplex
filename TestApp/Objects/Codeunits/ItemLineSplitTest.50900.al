// The company has no items, so the fixture builds its own customer and items from whichever
// existing customer has a usable General Posting Setup. The runner's isolation rolls all of it back.
codeunit 50900 "BAAN Item Line Split Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Access = Internal;

    var
        Customer: Record Customer;
        TestResults: Codeunit "BAAN Test Results";
        GenProdPostingGroupCode: Code[20];
        VATProdPostingGroupCode: Code[20];
        SalesAccountNo: Code[20];
        SalesCrMemoAccountNo: Code[20];
        ItemANo: Code[20];
        ItemBNo: Code[20];
        IsInitialized: Boolean;
        NoPostingSetupErr: Label 'No unblocked customer has a General Posting Setup with sales and credit memo accounts and a matching VAT Posting Setup.';
        EntryCountErr: Label 'Expected %1 G/L entries on account %2 for %3 %4, found %5.', Comment = '%1 = expected, %2 = account, %3 = document type, %4 = document no., %5 = found';
        LineEntryCountErr: Label 'Expected 1 G/L entry on account %1 with Item Line Description "%2", found %3.', Comment = '%1 = account, %2 = description, %3 = found';
        LineAmountErr: Label 'G/L entry %1 with Item Line Description "%2" has amount %3, expected %4.', Comment = '%1 = entry no., %2 = description, %3 = actual, %4 = expected';
        SetupLogTxt: Label 'Customer %1 copied from %2: Gen. Bus. %3, Gen. Prod. %4, VAT Bus. %5, VAT Prod. %6, sales account %7, credit memo account %8', Comment = '%1 = test customer, %2 = source customer, %3..%6 = posting groups, %7, %8 = G/L accounts', Locked = true;
        DimensionLogTxt: Label 'Mandatory dimension %1 = %2 added to the test customer', Comment = '%1 = dimension, %2 = value', Locked = true;
        PostedLogTxt: Label '%1 %2 posted as %3', Comment = '%1 = document type, %2 = draft no., %3 = posted no.', Locked = true;
        EntryLogTxt: Label 'G/L entry %1: account %2, amount %3, Description "%4", Item Line Description "%5"', Comment = '%1 = entry no., %2 = account, %3 = amount, %4, %5 = descriptions', Locked = true;

    // Lines 1 and 3 sell the same item and all three Item lines share one General Posting Setup,
    // so standard posting would add them into a single G/L entry.
    [Test]
    procedure ItemLinesOnInvoicePostToSeparateGLEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        AddLine(SalesHeader, "Sales Line Type"::Item, ItemANo, 'Item A - first line', 2, 125);
        AddLine(SalesHeader, "Sales Line Type"::Item, ItemBNo, 'Item B', 1, 80);
        AddLine(SalesHeader, "Sales Line Type"::Item, ItemANo, 'Item A - second line', 3, 125);

        Post(SalesHeader);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        LogPosting(SalesHeader, SalesInvoiceHeader."No.", GLEntry."Document Type"::Invoice);
        VerifyEntryCount(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, 3);
        VerifyItemLineEntry(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, 'Item A - first line', -250);
        VerifyItemLineEntry(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, 'Item B', -80);
        VerifyItemLineEntry(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, 'Item A - second line', -375);
    end;

    [Test]
    procedure ItemLinesOnCreditMemoPostToSeparateGLEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        GLEntry: Record "G/L Entry";
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        AddLine(SalesHeader, "Sales Line Type"::Item, ItemANo, 'Item A - credit one', 1, 125);
        AddLine(SalesHeader, "Sales Line Type"::Item, ItemANo, 'Item A - credit two', 2, 125);

        Post(SalesHeader);

        SalesCrMemoHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesCrMemoHeader.FindFirst();
        LogPosting(SalesHeader, SalesCrMemoHeader."No.", GLEntry."Document Type"::"Credit Memo");
        VerifyEntryCount(GLEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.", SalesCrMemoAccountNo, 2);
        VerifyItemLineEntry(GLEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.", SalesCrMemoAccountNo, 'Item A - credit one', 125);
        VerifyItemLineEntry(GLEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.", SalesCrMemoAccountNo, 'Item A - credit two', 250);
    end;

    [Test]
    procedure GLAccountLinesStillCombine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        Initialize();
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        AddLine(SalesHeader, "Sales Line Type"::"G/L Account", SalesAccountNo, 'G/L line one', 1, 100);
        AddLine(SalesHeader, "Sales Line Type"::"G/L Account", SalesAccountNo, 'G/L line two', 1, 50);

        Post(SalesHeader);

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        LogPosting(SalesHeader, SalesInvoiceHeader."No.", GLEntry."Document Type"::Invoice);
        VerifyEntryCount(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, 1);
        VerifyItemLineEntry(GLEntry."Document Type"::Invoice, SalesInvoiceHeader."No.", SalesAccountNo, '', -150);
    end;

    local procedure Initialize()
    begin
        // A failing test rolls back the fixture it built, so the flag alone is not enough.
        if IsInitialized and Customer.Find() then
            exit;

        RelaxSetup();
        CreateCustomer();
        AddMandatoryDimensions();
        AllowDirectPosting(SalesAccountNo);
        ItemANo := CreateItem('BAAN-ITEM-A', 'BAAN test item A');
        ItemBNo := CreateItem('BAAN-ITEM-B', 'BAAN test item B');
        IsInitialized := true;
    end;

    // Copy Line Descr. and discount posting would also change how entries combine, so the tests
    // pin them; the remaining settings only stand between a test document and posting.
    local procedure RelaxSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        Workflow: Record Workflow;
    begin
        SalesSetup.Get();
        SalesSetup."Copy Line Descr. to G/L Entry" := false;
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"No Discounts";
        SalesSetup."Ext. Doc. No. Mandatory" := false;
        SalesSetup."Exact Cost Reversing Mandatory" := false;
        SalesSetup.Modify();

        GLSetup.Get();
        GLSetup."Allow Posting From" := 0D;
        GLSetup."Allow Posting To" := 0D;
        GLSetup.Modify();

        if not UserSetup.Get(UserId()) then begin
            UserSetup.Init();
            UserSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserSetup."User ID"));
            UserSetup.Insert();
        end;
        UserSetup."Allow Posting From" := 0D;
        UserSetup."Allow Posting To" := 0D;
        UserSetup.Modify();

        // ModifyAll skips the trigger that refuses to edit an enabled workflow.
        Workflow.SetRange(Enabled, true);
        Workflow.ModifyAll(Enabled, false);
    end;

    local procedure CreateCustomer()
    var
        SourceCustomer: Record Customer;
    begin
        SourceCustomer.SetRange(Blocked, SourceCustomer.Blocked::" ");
        SourceCustomer.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        SourceCustomer.SetFilter("Customer Posting Group", '<>%1', '');
        if SourceCustomer.FindSet() then
            repeat
                if FindPostingSetup(SourceCustomer) then begin
                    Customer.Init();
                    Customer."No." := 'BAAN-CUST';
                    Customer.Name := 'BAAN test customer';
                    Customer."Gen. Bus. Posting Group" := SourceCustomer."Gen. Bus. Posting Group";
                    Customer."VAT Bus. Posting Group" := SourceCustomer."VAT Bus. Posting Group";
                    Customer."Customer Posting Group" := SourceCustomer."Customer Posting Group";
                    Customer."Payment Terms Code" := SourceCustomer."Payment Terms Code";
                    Customer.Insert(false);
                    TestResults.Log(StrSubstNo(SetupLogTxt, Customer."No.", SourceCustomer."No.",
                        Customer."Gen. Bus. Posting Group", GenProdPostingGroupCode, Customer."VAT Bus. Posting Group",
                        VATProdPostingGroupCode, SalesAccountNo, SalesCrMemoAccountNo));
                    exit;
                end;
            until SourceCustomer.Next() = 0;
        Error(NoPostingSetupErr);
    end;

    local procedure FindPostingSetup(SourceCustomer: Record Customer): Boolean
    var
        GenPostingSetup: Record "General Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if not CustomerPostingGroup.Get(SourceCustomer."Customer Posting Group") then
            exit(false);
        if not IsPostingAccount(CustomerPostingGroup."Receivables Account") then
            exit(false);

        GenPostingSetup.SetRange("Gen. Bus. Posting Group", SourceCustomer."Gen. Bus. Posting Group");
        GenPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetup.SetFilter("Sales Credit Memo Account", '<>%1', '');
        GenPostingSetup.SetRange(Blocked, false);
        if GenPostingSetup.FindSet() then
            repeat
                if IsPostingAccount(GenPostingSetup."Sales Account") and
                   IsPostingAccount(GenPostingSetup."Sales Credit Memo Account") and
                   FindVATProdPostingGroup(SourceCustomer."VAT Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group")
                then begin
                    GenProdPostingGroupCode := GenPostingSetup."Gen. Prod. Posting Group";
                    SalesAccountNo := GenPostingSetup."Sales Account";
                    SalesCrMemoAccountNo := GenPostingSetup."Sales Credit Memo Account";
                    exit(true);
                end;
            until GenPostingSetup.Next() = 0;
        exit(false);
    end;

    local procedure FindVATProdPostingGroup(VATBusPostingGroupCode: Code[20]; GenProdPostingGroup: Code[20]): Boolean
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if GenProductPostingGroup.Get(GenProdPostingGroup) then
            if VATPostingSetup.Get(VATBusPostingGroupCode, GenProductPostingGroup."Def. VAT Prod. Posting Group") then
                if not VATPostingSetup.Blocked then begin
                    VATProdPostingGroupCode := VATPostingSetup."VAT Prod. Posting Group";
                    exit(true);
                end;

        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VATPostingSetup.SetRange(Blocked, false);
        if not VATPostingSetup.FindFirst() then
            exit(false);
        VATProdPostingGroupCode := VATPostingSetup."VAT Prod. Posting Group";
        exit(true);
    end;

    local procedure IsPostingAccount(GLAccountNo: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(GLAccountNo) then
            exit(false);
        exit((GLAccount."Account Type" = GLAccount."Account Type"::Posting) and not GLAccount.Blocked);
    end;

    // Dimensions that the accounts or the Customer/Item tables require go on the test customer,
    // so the document picks them up from its sell-to customer like a real invoice would.
    local procedure AddMandatoryDimensions()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        DefaultDimension.SetFilter("Value Posting", '%1|%2',
            DefaultDimension."Value Posting"::"Code Mandatory", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.SetRange("Table ID", Database::"G/L Account");
        DefaultDimension.SetFilter("No.", '%1|%2|%3|%4', '', SalesAccountNo, SalesCrMemoAccountNo, CustomerPostingGroup."Receivables Account");
        AddCustomerDimensions(DefaultDimension);

        DefaultDimension.SetFilter("Table ID", '%1|%2', Database::Customer, Database::Item);
        DefaultDimension.SetRange("No.", '');
        AddCustomerDimensions(DefaultDimension);
    end;

    local procedure AddCustomerDimensions(var RequiredDimension: Record "Default Dimension")
    var
        CustomerDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        ValueCode: Code[20];
    begin
        if not RequiredDimension.FindSet() then
            exit;
        repeat
            if not CustomerDimension.Get(Database::Customer, Customer."No.", RequiredDimension."Dimension Code") then begin
                ValueCode := RequiredDimension."Dimension Value Code";
                if ValueCode = '' then begin
                    DimensionValue.SetRange("Dimension Code", RequiredDimension."Dimension Code");
                    DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
                    DimensionValue.SetRange(Blocked, false);
                    DimensionValue.FindFirst();
                    ValueCode := DimensionValue.Code;
                end;
                CustomerDimension.Init();
                CustomerDimension."Table ID" := Database::Customer;
                CustomerDimension."No." := Customer."No.";
                CustomerDimension."Dimension Code" := RequiredDimension."Dimension Code";
                CustomerDimension."Dimension Value Code" := ValueCode;
                CustomerDimension.Insert(true);
                TestResults.Log(StrSubstNo(DimensionLogTxt, CustomerDimension."Dimension Code", ValueCode));
            end;
        until RequiredDimension.Next() = 0;
    end;

    local procedure AllowDirectPosting(GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        if GLAccount."Direct Posting" then
            exit;
        GLAccount."Direct Posting" := true;
        GLAccount.Modify();
    end;

    local procedure CreateItem(ItemNo: Code[20]; ItemDescription: Text[100]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := ItemNo;
        Item.Insert(true);
        Item.Validate(Description, ItemDescription);
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Validate("Base Unit of Measure", GetUnitOfMeasureCode());
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Validate("Unit Price", 100);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetUnitOfMeasureCode(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := 'PCS';
        UnitOfMeasure.Description := 'Piece';
        UnitOfMeasure.Insert(true);
        exit(UnitOfMeasure.Code);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("External Document No.", 'BAAN');
        // Bond's Field Additions and Custom Reports refuses to post a sales document without one.
        SalesHeader.Validate("Assigned User ID", CopyStr(UserId(), 1, MaxStrLen(SalesHeader."Assigned User ID")));
        SalesHeader.Modify(true);
    end;

    // Description is assigned rather than validated: validating it on an Item line can look up
    // an item by description.
    local procedure AddLine(SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; No: Code[20]; LineDescription: Text[100]; Qty: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        LineNo := 10000;
        if SalesLine.FindLast() then
            LineNo := SalesLine."Line No." + 10000;

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine."Line No." := LineNo;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, LineType);
        SalesLine.Validate("No.", No);
        if SalesLine."Gen. Prod. Posting Group" = '' then
            SalesLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesLine.Description := LineDescription;
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure Post(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesHeader.Find();
        SalesHeader.Ship := SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice;
        SalesHeader.Receive := SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo";
        SalesHeader.Invoice := true;
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
    end;

    local procedure LogPosting(SalesHeader: Record "Sales Header"; PostedNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
    begin
        TestResults.Log(StrSubstNo(PostedLogTxt, SalesHeader."Document Type", SalesHeader."No.", PostedNo));
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", PostedNo);
        if GLEntry.FindSet() then
            repeat
                TestResults.Log(StrSubstNo(EntryLogTxt, GLEntry."Entry No.", GLEntry."G/L Account No.",
                    Format(GLEntry.Amount, 0, 9), GLEntry.Description, GLEntry."BAAN Item Line Description"));
            until GLEntry.Next() = 0;
    end;

    local procedure VerifyEntryCount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Expected: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        if GLEntry.Count() <> Expected then
            Error(EntryCountErr, Expected, GLAccountNo, DocumentType, DocumentNo, GLEntry.Count());
    end;

    local procedure VerifyItemLineEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; ItemLineDescription: Text[100]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("BAAN Item Line Description", ItemLineDescription);
        if GLEntry.Count() <> 1 then
            Error(LineEntryCountErr, GLAccountNo, ItemLineDescription, GLEntry.Count());
        GLEntry.FindFirst();
        if GLEntry.Amount <> ExpectedAmount then
            Error(LineAmountErr, GLEntry."Entry No.", ItemLineDescription, GLEntry.Amount, ExpectedAmount);
    end;
}
