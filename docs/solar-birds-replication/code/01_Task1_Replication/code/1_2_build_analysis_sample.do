*==========================================================================
* 1_2_build_analysis_sample.do
* PURPOSE : Build the authors' analysis sample (46,528 county-months) using
*           their own data-preparation code VERBATIM (Part A), then add the
*           flags our later checks need (Part B). Saves data/analysis_sample.dta
* WHY     : Every later step (Tasks 1-3) must start from exactly the sample
*           the authors analysed.
*==========================================================================

*-------------------------------------------------------------------------
* PART A — authors' data preparation (CODE.do lines 1-245, unchanged)
*-------------------------------------------------------------------------
*------------------------------------------------------------------------
* Data preparation
*------------------------------------------------------------------------
cd "$DATA"   // [PATH] originally the authors' local DATA folder

*核心变量+控制变量
use "Bird.dta",clear
merge 1:1 id year using "BTN.dta",keepus(BT BN)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI.dta",keepus(PI)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "Climate.dta",keepus(Avt Wind)
drop if _merge==2
drop _merge
rename Avt Temp
merge m:1 id YEAR using "PD.dta",keepus(PD)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "air.dta",keepus(CO2 PM)
drop if _merge==2
drop _merge
rename PM PM25
merge m:1 id YEAR using "TD.dta",keepus(Water Green Farm Grass)
drop if _merge==2
drop _merge


*稳健性
**替换PI
merge m:1 id YEAR using "PI1.dta",keepus(PI1)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI2.dta",keepus(PI2)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI3.dta",keepus(PI3)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI4.dta",keepus(PI4)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI5.dta",keepus(PI5)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "PI6.dta",keepus(PI6)
drop if _merge==2
drop _merge
replace PI1 = 0 if missing(PI1)
replace PI2 = 0 if missing(PI2)
replace PI3 = 0 if missing(PI3)
replace PI4 = 0 if missing(PI4)
replace PI5 = 0 if missing(PI5)
replace PI6 = 0 if missing(PI6)
**王老师装机规模
merge m:1 id YEAR using "IC.dta",keepus(ICtotal)
drop if _merge==2
drop _merge
replace ICtotal=0 if missing(ICtotal)
**省会城市直辖市cities
merge m:1 省 市 using "cities.dta",keepus(cities)
drop if _merge==2
drop _merge
replace cities = 0 if missing(cities)
**环保督察政策CEI
merge m:1 省 YEAR using "enin.dta",keepus(enin)
drop if _merge==2
drop _merge
rename enin CEI
**煤电厂
merge m:1 id YEAR using "Coal.dta",keepus(FFP)
drop if _merge==2
drop _merge	
gen 煤电厂=0 
replace 煤电厂=1 if FFP !=.	
rename 煤电厂 Coal
**风电扩张
merge m:1 id YEAR using "Windexp.dta",keepus(风电数量)
drop if _merge==2
drop _merge	
gen 风电扩张=0 
replace 风电扩张=1 if 风电数量 !=0	
rename 风电扩张 Windexp
**绿色金融
gen 绿色金融 = 0
local group1 "湖州市 衢州市 广州市 哈密市 昌吉回族自治州 克拉玛依市"
foreach city in `group1' {
    replace 绿色金融 = 1 if strpos(市, "`city'") > 0 & (YEAR > 2017 | (YEAR == 2017 & month >= 7))
}
*赣江新区
replace 绿色金融 = 1 if (strpos(市, "南昌市") > 0 & (strpos(县, "新建区") > 0 | strpos(县, "青山湖区") > 0)) ///
                & (YEAR > 2017 | (YEAR == 2017 & month >= 7))
replace 绿色金融 = 1 if (strpos(市, "九江市") > 0 & (strpos(县, "共青城市") > 0 | strpos(县, "永修县") > 0)) ///
                & (YEAR > 2017 | (YEAR == 2017 & month >= 7))
*贵安新区
replace 绿色金融 = 1 if (strpos(市, "贵阳市") > 0) ///
                & (YEAR > 2017 | (YEAR == 2017 & month >= 7))
replace 绿色金融 = 1 if (strpos(市, "安顺市") > 0 & strpos(县, "平坝区") > 0) ///
                & (YEAR > 2017 | (YEAR == 2017 & month >= 7))
* 兰州新区
replace 绿色金融 = 1 if (strpos(市, "兰州市") > 0 & (strpos(县, "皋兰县") > 0 | strpos(县, "永登县") > 0)) ///
                & (YEAR > 2019 | (YEAR == 2019 & month >= 12))
* 重庆市
replace 绿色金融 = 1 if strpos(市, "重庆市") > 0 ///
                & (YEAR > 2022 | (YEAR == 2022 & month >= 9))
rename 绿色金融 Greenfin
**IV 
***sun算术平均1984-2013
merge m:1 id YEAR using "sunshine.dta",keepus(sun)
drop if _merge==2
drop _merge
***地级市CPU
merge m:1 市 YEAR using "CCPU.dta",keepus(CCPU)
drop if _merge==2
drop _merge
**高PI县相邻县
merge m:1 id using "highPI.dta",keepus(is_neighbor_of_highPI)
drop if _merge==2
drop _merge
replace is_neighbor_of_highPI=0 if missing(is_neighbor_of_highPI)
**剔除低于最低观鸟记录阈值的观测值
merge 1:1 id year using "BirdDrop3.dta",keepus(ShannonBD3)
drop if _merge==2
drop _merge
merge 1:1 id year using "BirdDrop5.dta",keepus(ShannonBD5)
drop if _merge==2
drop _merge
merge 1:1 id year using "BirdDrop10.dta",keepus(ShannonBD10)
drop if _merge==2
drop _merge
merge 1:1 id year using "BirdDrop20.dta",keepus(ShannonBD20)
drop if _merge==2
drop _merge


*异质性
**贫困县poverty_county、三北地区north_region、低碳试点low_carbon_city
merge m:1 县 using "poverty.dta",keepus(poverty_county)
drop if _merge==2
drop _merge
replace poverty_county = 0 if missing(poverty_county)
merge m:1 省 using "north_region.dta",keepus(north_region)
drop if _merge==2
drop _merge
replace north_region = 0 if missing(north_region)
merge m:1 id using "Gebi.dta",keepus(desert_gobi)
drop if _merge==2
drop _merge
**候鸟Migratory、留鸟Resident+特有物种Endemic、非特有物种non_Endemic+国家保护Protected、非国家保护non_Protected
merge 1:1 id year using "Migratory.dta", keepus(Migratory)
drop if _merge==2
drop _merge
merge 1:1 id year using "Resident.dta", keepus(Resident)
drop if _merge==2
drop _merge
merge 1:1 id year using "Endemic.dta", keepus(Endemic)
drop if _merge==2
drop _merge
merge 1:1 id year using "non_Endemic.dta", keepus(non_Endemic)
drop if _merge==2
drop _merge
merge 1:1 id year using "Protected.dta", keepus(Protected)
drop if _merge==2
drop _merge
merge 1:1 id year using "non_Protected.dta", keepus(non_Protected)
drop if _merge==2
drop _merge
**植物筑巢Nest_veg、水上筑巢Land_water+食肉杂食non_herbivorous、食草Herbivorous+小群落Small_flock、大群落Large_flock
merge 1:1 id year using "Nest_veg.dta", keepus(Nest_veg)
drop if _merge==2
drop _merge
merge 1:1 id year using "Land_water.dta", keepus(Land_water)
drop if _merge==2
drop _merge
merge 1:1 id year using "non_Herbivorous.dta", keepus(non_Herbivorous)
drop if _merge==2
drop _merge
merge 1:1 id year using "Herbivorous.dta", keepus(Herbivorous)
drop if _merge==2
drop _merge
merge 1:1 id year using "Small_flock.dta", keepus(Small_flock)
drop if _merge==2
drop _merge
merge 1:1 id year using "Large_flock.dta", keepus(Large_flock)
drop if _merge==2
drop _merge


*机制
merge m:1 id YEAR using "Ndvi.dta",keepus(Ndvi)
drop if _merge==2
drop _merge
replace Ndvi = Ndvi*100
merge m:1 id YEAR using "NL.dta",keepus(Nightlight)
drop if _merge==2
drop _merge
merge m:1 id YEAR using "LAI.dta",keepus(LAI)
drop if _merge==2
drop _merge


*经济后果
**丰富度与均匀度
merge 1:1 id year using "Richeven.dta",keepus(丰富度)
drop if _merge==2
drop _merge
gen 均匀度 = ShannonBD/ln(丰富度)
rename 丰富度 Richness
rename 均匀度 Evenness
**农作物产量
merge m:1 id YEAR using "AP.dta",keepus(APtotal)
drop if _merge==2
drop _merge


*数据预处理
**生成人均观鸟时长
gen BTN=BT/BN
**PI缺失值替换为0
replace PI = 0 if missing(PI)
**剔除控制变量存在缺失的样本
drop if missing(Temp, Wind, PD, BTN, CO2, Water, Green, Farm, Grass)
**王老师装机规模换算成面积
gen Area = ICtotal*1000/0.15
replace Area = Area / 1000000
label var Area "集中式光伏电站面积平方千米"
**取对数
gen Pop=ln(PD)
gen Duration=ln(BTN+1)
gen Carbon=ln(CO2)
gen PM=ln(PM25)
gen Output = ln(APtotal) 
**所有连续变量缩尾
local var "ShannonBD SimpsonBD PI Temp Wind Pop Duration Carbon Water Green Farm Grass PM ICtotal Area Ndvi Nightlight LAI PI1 PI2 PI3 PI4 PI5 PI6 Migratory Resident Endemic non_Endemic Protected non_Protected Nest_veg Land_water non_Herbivorous Herbivorous Small_flock Large_flock Richness Evenness Output ShannonBD3 ShannonBD5 ShannonBD10 ShannonBD20 sun CCPU"
winsor2 `var', cuts(1 99) replace
**生成IV
gen lnsun = ln(sun)
gen inv_CCPU = 1 / CCPU
gen Sun_ccpu = lnsun / CCPU
**生成county
egen county = group(id)




*-------------------------------------------------------------------------
* PART B — flags added for our analysis (not in the authors' code)
*-------------------------------------------------------------------------
* (1) Does the county appear in the PSI source file at all?
*     The authors set PSI = 0 whenever it is missing (line "replace PI = 0").
preserve
    use "$DATA/PI.dta", clear
    keep id
    duplicates drop
    gen byte in_PI_file = 1
    tempfile pif
    save `pif'
restore
merge m:1 id using `pif', keep(master match) nogen
replace in_PI_file = 0 if missing(in_PI_file)
label var in_PI_file "County present in PI.dta (1) or PSI imputed as 0 (0)"

* (2) Urban district vs rural county (Chinese admin code: last two digits
*     01-20 = urban district 'shixiaqu'; 21+ = county / county-level city)
gen byte urban = mod(id,100) <= 20
label var urban "Urban district (admin code ending 01-20)"
* name check: urban districts are named ...区 (district)
gen byte name_is_district = ustrregexm(县, "区$")
label var name_is_district "County name ends in 区 (district)"

* (3) Alternative PSI definitions kept in PI.dta but unused by the authors
merge m:1 id YEAR using "$DATA/PI.dta", keepusing(PI_stock PI_total) keep(master match) nogen
gen byte any_PSI = (PI > 0)
label var any_PSI "PSI > 0 in this year"

* (4) Identifiers
egen prov = group(省)
egen city = group(市)
gen month_of_year = month
label var prov "Province id"
label var city "Prefecture city id"

compress
save "$SAMPLE", replace
di as res "Analysis sample saved: " _N " county-months"
