permissionset 89000 "BAAN Tests"
{
    Caption = 'Item Line Posting Tests';
    Assignable = true;
    Permissions =
        tabledata "BAAN Test Run" = RIMD,
        table "BAAN Test Run" = X,
        page "BAAN Test Runs API" = X,
        codeunit "BAAN Test Runner" = X,
        codeunit "BAAN Test Results" = X,
        codeunit "BAAN Item Line Split Test" = X;
}
