# Select the newest GDP vintage available at a given date

Select the newest GDP vintage available at a given date

## Usage

``` r
select_most_recent_GDP_vintage(current_date, GDP_gr_vintages)
```

## Arguments

- current_date:

  Numeric (decimal time), the evaluation date.

- GDP_gr_vintages:

  Vintage table from
  [`get_real_time_gdp_vintages()`](https://philippkronenberg.github.io/wai_ind_package/reference/get_real_time_gdp_vintages.md).

## Value

The selected vintage column (numeric vector).

## Examples

``` r
# \donttest{
vintages <- get_real_time_gdp_vintages("quarterly")
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
#> • `` -> `...36`
#> • `` -> `...37`
#> • `` -> `...38`
#> • `` -> `...39`
#> • `` -> `...40`
#> • `` -> `...41`
#> • `` -> `...42`
#> • `` -> `...43`
#> • `` -> `...44`
#> • `` -> `...45`
#> • `` -> `...46`
#> • `` -> `...47`
#> • `` -> `...48`
#> • `` -> `...49`
#> • `` -> `...50`
#> • `` -> `...51`
#> • `` -> `...52`
#> • `` -> `...53`
#> • `` -> `...54`
#> • `` -> `...55`
#> • `` -> `...56`
#> • `` -> `...57`
#> • `` -> `...58`
#> • `` -> `...59`
#> • `` -> `...60`
#> • `` -> `...61`
#> • `` -> `...62`
#> • `` -> `...63`
#> • `` -> `...64`
#> • `` -> `...65`
#> • `` -> `...66`
#> • `` -> `...67`
#> • `` -> `...68`
#> • `` -> `...69`
#> • `` -> `...70`
#> • `` -> `...71`
#> • `` -> `...72`
#> • `` -> `...73`
#> • `` -> `...74`
#> • `` -> `...75`
#> • `` -> `...76`
#> • `` -> `...77`
#> • `` -> `...78`
#> • `` -> `...79`
#> • `` -> `...80`
#> • `` -> `...81`
#> • `` -> `...82`
#> • `` -> `...83`
#> • `` -> `...84`
#> • `` -> `...85`
#> • `` -> `...86`
#> • `` -> `...87`
#> • `` -> `...88`
#> • `` -> `...89`
#> • `` -> `...90`
#> • `` -> `...91`
#> • `` -> `...92`
#> • `` -> `...93`
#> • `` -> `...94`
#> • `` -> `...95`
#> • `` -> `...96`
#> • `` -> `...97`
#> • `` -> `...98`
#> • `` -> `...99`
#> • `` -> `...100`
#> • `` -> `...101`
#> • `` -> `...102`
#> • `` -> `...103`
#> • `` -> `...104`
#> • `` -> `...105`
#> Warning: Expecting numeric in BW10 / R10C75: got a date
#> Warning: Expecting numeric in BX10 / R10C76: got a date
#> Warning: Expecting numeric in BY10 / R10C77: got a date
#> Warning: Expecting numeric in BZ10 / R10C78: got a date
#> Warning: Expecting numeric in CA10 / R10C79: got a date
#> Warning: Expecting numeric in CB10 / R10C80: got a date
#> Warning: Expecting numeric in CC10 / R10C81: got a date
#> Warning: Expecting numeric in CD10 / R10C82: got a date
#> Warning: Expecting numeric in CE10 / R10C83: got a date
#> Warning: Expecting numeric in CF10 / R10C84: got a date
#> Warning: Expecting numeric in CG10 / R10C85: got a date
#> Warning: Expecting numeric in CH10 / R10C86: got a date
#> Warning: Expecting numeric in CI10 / R10C87: got a date
#> Warning: Expecting numeric in CJ10 / R10C88: got a date
#> Warning: Expecting numeric in CK10 / R10C89: got a date
#> Warning: Expecting numeric in CL10 / R10C90: got a date
#> Warning: Expecting numeric in CM10 / R10C91: got a date
#> Warning: Expecting numeric in CN10 / R10C92: got a date
#> Warning: Expecting numeric in CO10 / R10C93: got a date
#> Warning: Expecting numeric in CP10 / R10C94: got a date
#> Warning: Expecting numeric in CQ10 / R10C95: got a date
#> Warning: Expecting numeric in CR10 / R10C96: got a date
#> Warning: Expecting numeric in CS10 / R10C97: got a date
#> Warning: Expecting numeric in CT10 / R10C98: got a date
#> Warning: Expecting numeric in CU10 / R10C99: got a date
#> Warning: Expecting numeric in CV10 / R10C100: got a date
#> Warning: Expecting numeric in CW10 / R10C101: got a date
#> Warning: Expecting numeric in CX10 / R10C102: got a date
#> Warning: Expecting numeric in CY10 / R10C103: got a date
#> Warning: Expecting numeric in CZ10 / R10C104: got a date
#> Warning: Expecting numeric in DA10 / R10C105: got a date
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
#> • `` -> `...36`
#> • `` -> `...37`
#> • `` -> `...38`
#> • `` -> `...39`
#> • `` -> `...40`
#> • `` -> `...41`
#> • `` -> `...42`
#> • `` -> `...43`
#> • `` -> `...44`
#> • `` -> `...45`
#> • `` -> `...46`
#> • `` -> `...47`
#> • `` -> `...48`
#> • `` -> `...49`
#> • `` -> `...50`
#> • `` -> `...51`
#> • `` -> `...52`
#> • `` -> `...53`
#> • `` -> `...54`
#> • `` -> `...55`
#> • `` -> `...56`
#> • `` -> `...57`
#> • `` -> `...58`
#> • `` -> `...59`
#> • `` -> `...60`
#> • `` -> `...61`
#> • `` -> `...62`
#> • `` -> `...63`
#> • `` -> `...64`
#> • `` -> `...65`
#> • `` -> `...66`
#> • `` -> `...67`
#> • `` -> `...68`
#> • `` -> `...69`
#> • `` -> `...70`
#> • `` -> `...71`
#> • `` -> `...72`
#> • `` -> `...73`
#> • `` -> `...74`
#> • `` -> `...75`
#> • `` -> `...76`
#> • `` -> `...77`
#> • `` -> `...78`
#> • `` -> `...79`
#> • `` -> `...80`
#> • `` -> `...81`
#> • `` -> `...82`
#> • `` -> `...83`
#> • `` -> `...84`
#> • `` -> `...85`
#> • `` -> `...86`
#> • `` -> `...87`
#> • `` -> `...88`
#> • `` -> `...89`
#> • `` -> `...90`
#> • `` -> `...91`
#> • `` -> `...92`
#> • `` -> `...93`
#> • `` -> `...94`
#> • `` -> `...95`
#> • `` -> `...96`
#> • `` -> `...97`
#> • `` -> `...98`
#> • `` -> `...99`
#> • `` -> `...100`
#> • `` -> `...101`
#> • `` -> `...102`
#> • `` -> `...103`
#> • `` -> `...104`
#> • `` -> `...105`
#> Warning: Expecting numeric in B10 / R10C2: got a date
#> Warning: Expecting numeric in C10 / R10C3: got a date
#> Warning: Expecting numeric in D10 / R10C4: got a date
#> Warning: Expecting numeric in E10 / R10C5: got a date
#> Warning: Expecting numeric in F10 / R10C6: got a date
#> Warning: Expecting numeric in G10 / R10C7: got a date
#> Warning: Expecting numeric in H10 / R10C8: got a date
#> Warning: Expecting numeric in I10 / R10C9: got a date
#> Warning: Expecting numeric in J10 / R10C10: got a date
#> Warning: Expecting numeric in K10 / R10C11: got a date
#> Warning: Expecting numeric in L10 / R10C12: got a date
#> Warning: Expecting numeric in M10 / R10C13: got a date
#> Warning: Expecting numeric in N10 / R10C14: got a date
#> Warning: Expecting numeric in O10 / R10C15: got a date
#> Warning: Expecting numeric in P10 / R10C16: got a date
#> Warning: Expecting numeric in Q10 / R10C17: got a date
#> Warning: Expecting numeric in R10 / R10C18: got a date
#> Warning: Expecting numeric in S10 / R10C19: got a date
#> Warning: Expecting numeric in T10 / R10C20: got a date
#> Warning: Expecting numeric in U10 / R10C21: got a date
#> Warning: Expecting numeric in V10 / R10C22: got a date
#> Warning: Expecting numeric in W10 / R10C23: got a date
#> Warning: Expecting numeric in X10 / R10C24: got a date
#> Warning: Expecting numeric in Y10 / R10C25: got a date
#> Warning: Expecting numeric in Z10 / R10C26: got a date
#> Warning: Expecting numeric in AA10 / R10C27: got a date
#> Warning: Expecting numeric in AB10 / R10C28: got a date
#> Warning: Expecting numeric in AC10 / R10C29: got a date
#> Warning: Expecting numeric in AD10 / R10C30: got a date
#> Warning: Expecting numeric in AE10 / R10C31: got a date
#> Warning: Expecting numeric in AF10 / R10C32: got a date
#> Warning: Expecting numeric in AG10 / R10C33: got a date
#> Warning: Expecting numeric in AH10 / R10C34: got a date
#> Warning: Expecting numeric in AI10 / R10C35: got a date
#> Warning: Expecting numeric in AJ10 / R10C36: got a date
#> Warning: Expecting numeric in AK10 / R10C37: got a date
#> Warning: Expecting numeric in AL10 / R10C38: got a date
#> Warning: Expecting numeric in AM10 / R10C39: got a date
#> Warning: Expecting numeric in AN10 / R10C40: got a date
#> Warning: Expecting numeric in AO10 / R10C41: got a date
#> Warning: Expecting numeric in AP10 / R10C42: got a date
#> Warning: Expecting numeric in AQ10 / R10C43: got a date
#> Warning: Expecting numeric in AR10 / R10C44: got a date
#> Warning: Expecting numeric in AS10 / R10C45: got a date
#> Warning: Expecting numeric in AT10 / R10C46: got a date
#> Warning: Expecting numeric in AU10 / R10C47: got a date
#> Warning: Expecting numeric in AV10 / R10C48: got a date
#> Warning: Expecting numeric in AW10 / R10C49: got a date
#> Warning: Expecting numeric in AX10 / R10C50: got a date
#> Warning: Expecting numeric in AY10 / R10C51: got a date
#> Warning: Expecting numeric in AZ10 / R10C52: got a date
#> Warning: Expecting numeric in BA10 / R10C53: got a date
#> Warning: Expecting numeric in BB10 / R10C54: got a date
#> Warning: Expecting numeric in BC10 / R10C55: got a date
#> Warning: Expecting numeric in BD10 / R10C56: got a date
#> Warning: Expecting numeric in BE10 / R10C57: got a date
#> Warning: Expecting numeric in BF10 / R10C58: got a date
#> Warning: Expecting numeric in BG10 / R10C59: got a date
#> Warning: Expecting numeric in BH10 / R10C60: got a date
#> Warning: Expecting numeric in BI10 / R10C61: got a date
#> Warning: Expecting numeric in BJ10 / R10C62: got a date
#> Warning: Expecting numeric in BK10 / R10C63: got a date
#> Warning: Expecting numeric in BL10 / R10C64: got a date
#> Warning: Expecting numeric in BM10 / R10C65: got a date
#> Warning: Expecting numeric in BN10 / R10C66: got a date
#> Warning: Expecting numeric in BO10 / R10C67: got a date
#> Warning: Expecting numeric in BP10 / R10C68: got a date
#> Warning: Expecting numeric in BQ10 / R10C69: got a date
#> Warning: Expecting numeric in BR10 / R10C70: got a date
#> Warning: Expecting numeric in BS10 / R10C71: got a date
#> Warning: Expecting numeric in BT10 / R10C72: got a date
#> Warning: Expecting numeric in BU10 / R10C73: got a date
#> Warning: Expecting numeric in BV10 / R10C74: got a date
#> Warning: Expecting numeric in BW10 / R10C75: got a date
#> Warning: Expecting numeric in BX10 / R10C76: got a date
#> Warning: Expecting numeric in BY10 / R10C77: got a date
#> Warning: Expecting numeric in BZ10 / R10C78: got a date
#> Warning: Expecting numeric in CA10 / R10C79: got a date
#> Warning: Expecting numeric in CB10 / R10C80: got a date
#> Warning: Expecting numeric in CC10 / R10C81: got a date
#> Warning: Expecting numeric in CD10 / R10C82: got a date
#> Warning: Expecting numeric in CE10 / R10C83: got a date
#> Warning: Expecting numeric in CF10 / R10C84: got a date
#> Warning: Expecting numeric in CG10 / R10C85: got a date
#> Warning: Expecting numeric in CH10 / R10C86: got a date
#> Warning: Expecting numeric in CI10 / R10C87: got a date
#> Warning: Expecting numeric in CJ10 / R10C88: got a date
#> Warning: Expecting numeric in CK10 / R10C89: got a date
#> Warning: Expecting numeric in CL10 / R10C90: got a date
#> Warning: Expecting numeric in CM10 / R10C91: got a date
#> Warning: Expecting numeric in CN10 / R10C92: got a date
#> Warning: Expecting numeric in CO10 / R10C93: got a date
#> Warning: Expecting numeric in CP10 / R10C94: got a date
#> Warning: Expecting numeric in CQ10 / R10C95: got a date
#> Warning: Expecting numeric in CR10 / R10C96: got a date
#> Warning: Expecting numeric in CS10 / R10C97: got a date
#> Warning: Expecting numeric in CT10 / R10C98: got a date
#> Warning: Expecting numeric in CU10 / R10C99: got a date
#> Warning: Expecting numeric in CV10 / R10C100: got a date
#> Warning: Expecting numeric in CW10 / R10C101: got a date
#> Warning: Expecting numeric in CX10 / R10C102: got a date
#> Warning: Expecting numeric in CY10 / R10C103: got a date
#> Warning: Expecting numeric in CZ10 / R10C104: got a date
#> Warning: Expecting numeric in DA10 / R10C105: got a date
#> New names:
#> • `` -> `...1`
#> • `` -> `...2`
#> • `` -> `...3`
#> • `` -> `...4`
#> • `` -> `...5`
#> • `` -> `...6`
#> • `` -> `...7`
#> • `` -> `...8`
#> • `` -> `...9`
#> • `` -> `...10`
#> • `` -> `...11`
#> • `` -> `...12`
#> • `` -> `...13`
#> • `` -> `...14`
#> • `` -> `...15`
#> • `` -> `...16`
#> • `` -> `...17`
#> • `` -> `...18`
#> • `` -> `...19`
#> • `` -> `...20`
#> • `` -> `...21`
#> • `` -> `...22`
#> • `` -> `...23`
#> • `` -> `...24`
#> • `` -> `...25`
#> • `` -> `...26`
#> • `` -> `...27`
#> • `` -> `...28`
#> • `` -> `...29`
#> • `` -> `...30`
#> • `` -> `...31`
#> • `` -> `...32`
#> • `` -> `...33`
#> • `` -> `...34`
#> • `` -> `...35`
#> • `` -> `...36`
#> • `` -> `...37`
#> • `` -> `...38`
#> • `` -> `...39`
#> • `` -> `...40`
#> • `` -> `...41`
#> • `` -> `...42`
#> • `` -> `...43`
#> • `` -> `...44`
#> • `` -> `...45`
#> • `` -> `...46`
#> • `` -> `...47`
#> • `` -> `...48`
#> • `` -> `...49`
#> • `` -> `...50`
#> • `` -> `...51`
#> • `` -> `...52`
#> • `` -> `...53`
#> • `` -> `...54`
#> • `` -> `...55`
#> • `` -> `...56`
#> • `` -> `...57`
#> • `` -> `...58`
#> • `` -> `...59`
#> • `` -> `...60`
#> • `` -> `...61`
#> • `` -> `...62`
#> • `` -> `...63`
#> • `` -> `...64`
#> • `` -> `...65`
#> • `` -> `...66`
#> • `` -> `...67`
#> • `` -> `...68`
#> • `` -> `...69`
#> • `` -> `...70`
#> • `` -> `...71`
#> • `` -> `...72`
#> • `` -> `...73`
#> • `` -> `...74`
#> • `` -> `...75`
#> • `` -> `...76`
#> • `` -> `...77`
#> • `` -> `...78`
#> • `` -> `...79`
#> • `` -> `...80`
#> • `` -> `...81`
#> • `` -> `...82`
#> • `` -> `...83`
#> • `` -> `...84`
#> • `` -> `...85`
#> • `` -> `...86`
#> • `` -> `...87`
#> • `` -> `...88`
#> • `` -> `...89`
#> • `` -> `...90`
#> • `` -> `...91`
#> • `` -> `...92`
#> • `` -> `...93`
#> • `` -> `...94`
#> • `` -> `...95`
#> • `` -> `...96`
#> • `` -> `...97`
#> • `` -> `...98`
#> • `` -> `...99`
#> • `` -> `...100`
#> • `` -> `...101`
#> • `` -> `...102`
#> • `` -> `...103`
#> • `` -> `...104`
v <- select_most_recent_GDP_vintage(2024.5, vintages)
utils::tail(stats::na.omit(v))
#> [1]  0.0005006722  0.0091940850 -0.0025524009  0.0026667204  0.0033793290
#> [6]  0.0027648443
# }
```
