IF OBJECT_ID ( 'dbo.v_VersionList' ) IS NULL
EXEC sp_executesql N'CREATE FUNCTION dbo.v_VersionList ( ) RETURNS @Table TABLE ( _ BIT NULL ) AS BEGIN RETURN ; END' ;

GO

--
-- This function will result with dictionary of wait type names and descriptions.
--
-- Based on versions described here: https://buildnumbers.wordpress.com/sqlserver/
--
ALTER FUNCTION dbo.v_VersionList ( )
RETURNS @Table TABLE
(
  [Version] VARCHAR(20) ,
  [Family] VARCHAR(50) ,
  [Update] VARCHAR(20) ,
  UNIQUE CLUSTERED ( [Version] )
)
AS
BEGIN

INSERT INTO @Table ( [Version] , [Family] , [Update] )
VALUES
 ('','','')

,('15.0.4178.1','SQL Server 2019','CU13')
,('15.0.4153.1','SQL Server 2019','CU12')
,('15.0.4138.2','SQL Server 2019','CU11')
,('15.0.4123.1','SQL Server 2019','CU10')
,('15.0.4102.2','SQL Server 2019','CU9')
,('15.0.4083.2','SQL Server 2019','CU8+SU')
,('15.0.4073.23','SQL Server 2019','CU8')
,('15.0.4063.15','SQL Server 2019','CU7')
,('15.0.4053.23','SQL Server 2019','CU6')
,('15.0.4043.16','SQL Server 2019','CU5')
,('15.0.4033.1','SQL Server 2019','CU4')
,('15.0.4023.6','SQL Server 2019','CU3')
,('15.0.4013.40','SQL Server 2019','CU2')
,('15.0.4003.23','SQL Server 2019','CU1')
,('15.0.2080.9','SQL Server 2019','GDR+SU')
,('15.0.2070.41','SQL Server 2019','GDR1')
,('15.0.2000.5','SQL Server 2019','RTM')

,('15.0.1900.47','SQL Server 2019 RTM','RC1 1.1')
,('15.0.1900.25','SQL Server 2019 RTM','RC1')
,('15.0.1800.32','SQL Server 2019 RTM','CTP 3.2')
,('15.0.1700.37','SQL Server 2019 RTM','CTP 3.1')
,('15.0.1600.8','SQL Server 2019 RTM','CTP 3.0')
,('15.0.1500.28','SQL Server 2019 RTM','CTP 2.5')
,('15.0.1400.75','SQL Server 2019 RTM','CTP 2.4')
,('15.0.1300.359','SQL Server 2019 RTM','CTP 2.3')
,('15.0.1200.24','SQL Server 2019 RTM','CTP 2.2')
,('15.0.1100.94','SQL Server 2019 RTM','CTP 2.1')
,('15.0.1000.34','SQL Server 2019 RTM','CTP 2.0')

,('14.0.3411.3','SQL Server 2017','CU26')
,('14.0.3401.7','SQL Server 2017','CU25')
,('14.0.3391.2','SQL Server 2017','CU24')
,('14.0.3381.3','SQL Server 2017','CU23')
,('14.0.3370.1','SQL Server 2017','CU22+SU')
,('14.0.3356.20','SQL Server 2017','CU22')
,('14.0.3335.7','SQL Server 2017','CU21')
,('14.0.3294.2','SQL Server 2017','CU20')
,('14.0.3281.6','SQL Server 2017','CU19')
,('14.0.3257.3','SQL Server 2017','CU18')
,('14.0.3238.1','SQL Server 2017','CU17')
,('14.0.3223.3','SQL Server 2017','CU16')
,('14.0.3208.1','SQL Server 2017','CU15+SU2+FIX')
,('14.0.3192.2','SQL Server 2017','CU15+SU1')
,('14.0.3164.1','SQL Server 2017','CU15+FIX')
,('14.0.3162.1','SQL Server 2017','CU15')
,('14.0.3103.1','SQL Server 2017','CU14+SU')
,('14.0.3076.1','SQL Server 2017','CU14')
,('14.0.3049.1','SQL Server 2017','FIX')
,('14.0.3048.4','SQL Server 2017','CU13')
,('14.0.3045.24','SQL Server 2017','CU12')
,('14.0.3038.14','SQL Server 2017','CU11')
,('14.0.3037.1','SQL Server 2017','CU10')
,('14.0.3035.2','SQL Server 2017','CU9+SU')
,('14.0.3030.27','SQL Server 2017','CU9')
,('14.0.3029.16','SQL Server 2017','CU8')
,('14.0.3026.27','SQL Server 2017','CU7')
,('14.0.3025.34','SQL Server 2017','CU6')
,('14.0.3023.8','SQL Server 2017','CU5')
,('14.0.3022.28','SQL Server 2017','CU4')
,('14.0.3015.40','SQL Server 2017','CU3')
,('14.0.3008.27','SQL Server 2017','CU2')
,('14.0.3006.16','SQL Server 2017','CU1')
,('14.0.2037.2','SQL Server 2017','GDR+SU5')
,('14.0.2027.2','SQL Server 2017','GDR+SU4')
,('14.0.2014.14','SQL Server 2017','GDR+SU3')
,('14.0.2002.14','SQL Server 2017','GDR+SU2')
,('14.0.2000.63','SQL Server 2017','GDR+SU1')
,('14.0.1000.169','SQL Server 2017','RTM')
,('14.0.900.75','SQL Server 2017','RC2')
,('14.0.800.90','SQL Server 2017','RC1')
,('14.0.600.250','SQL Server 2017','CTP 2.1')
,('14.0.500.272','SQL Server 2017','CTP 2.0')
,('14.0.405.198','SQL Server 2017','CTP 1.4')
,('14.0.304.138','SQL Server 2017','CTP 1.3')
,('14.0.200.24','SQL Server 2017','CTP 1.2')
,('14.0.100.187','SQL Server 2017','CTP 1.1')
,('14.0.1.246','SQL Server 2017','CTP 1')

,('13.0.6300.2','SQL Server 2016 Service Pack 3','SP3')
,('13.0.5888.11','SQL Server 2016 Service Pack 2','CU17')
,('13.0.5882.1','SQL Server 2016 Service Pack 2','CU16')
,('13.0.5865.1','SQL Server 2016 Service Pack 2','CU15+SU')
,('13.0.5850.14','SQL Server 2016 Service Pack 2','CU15')
,('13.0.5830.85','SQL Server 2016 Service Pack 2','CU14')
,('13.0.5820.21','SQL Server 2016 Service Pack 2','CU13')
,('13.0.5698.0','SQL Server 2016 Service Pack 2','CU12')
,('13.0.5622.0','SQL Server 2016 Service Pack 2','CU11+SU')
,('13.0.5598.27','SQL Server 2016 Service Pack 2','CU11')
,('13.0.5492.2','SQL Server 2016 Service Pack 2','CU10')
,('13.0.5479.0','SQL Server 2016 Service Pack 2','CU9')
,('13.0.5426.0','SQL Server 2016 Service Pack 2','CU8')
,('13.0.5382.0','SQL Server 2016 Service Pack 2','CU7+SU2+FIX')
,('13.0.5366.0','SQL Server 2016 Service Pack 2','CU7+SU1')
,('13.0.5343.1','SQL Server 2016 Service Pack 2','CU7+FIX')
,('13.0.5337.0','SQL Server 2016 Service Pack 2','CU7')
,('13.0.5292.0','SQL Server 2016 Service Pack 2','CU6')
,('13.0.5270.0','SQL Server 2016 Service Pack 2','CU5+FIX')
,('13.0.5264.1','SQL Server 2016 Service Pack 2','CU5')
,('13.0.5239.0','SQL Server 2016 Service Pack 2','CU4+FIX')
,('13.0.5233.0','SQL Server 2016 Service Pack 2','CU4')
,('13.0.5216.0','SQL Server 2016 Service Pack 2','CU3')
,('13.0.5201.1','SQL Server 2016 Service Pack 2','CU2+SU')
,('13.0.5153.0','SQL Server 2016 Service Pack 2','CU2')
,('13.0.5149.0','SQL Server 2016 Service Pack 2','CU1')
,('13.0.5103.6','SQL Server 2016 Service Pack 2','GDR+SU4')
,('13.0.5102.14','SQL Server 2016 Service Pack 2','GDR+SU3')
,('13.0.5101.9','SQL Server 2016 Service Pack 2','GDR+SU2')
,('13.0.5081.1','SQL Server 2016 Service Pack 2','GDR+SU1')
,('13.0.5026.0','SQL Server 2016 Service Pack 2','SP2')
,('13.0.4604.0','SQL Server 2016 Service Pack 1','CU15+SU')
,('13.0.4577.0','SQL Server 2016 Service Pack 1','CU15+FIX')
,('13.0.4574.0','SQL Server 2016 Service Pack 1','CU15')
,('13.0.4560.0','SQL Server 2016 Service Pack 1','CU14')
,('13.0.4550.1','SQL Server 2016 Service Pack 1','CU13')
,('13.0.4541.0','SQL Server 2016 Service Pack 1','CU12')
,('13.0.4531.0','SQL Server 2016 Service Pack 1','CU11+FIX')
,('13.0.4528.0','SQL Server 2016 Service Pack 1','CU11')
,('13.0.4522.0','SQL Server 2016 Service Pack 1','CU10+SU')
,('13.0.4514.0','SQL Server 2016 Service Pack 1','CU10')
,('13.0.4502.0','SQL Server 2016 Service Pack 1','CU9')
,('13.0.4474.0','SQL Server 2016 Service Pack 1','CU8')
,('13.0.4466.4','SQL Server 2016 Service Pack 1','CU7')
,('13.0.4457.0','SQL Server 2016 Service Pack 1','CU6')
,('13.0.4451.0','SQL Server 2016 Service Pack 1','CU5')
,('13.0.4446.0','SQL Server 2016 Service Pack 1','CU4')
,('13.0.4435.0','SQL Server 2016 Service Pack 1','CU3')
,('13.0.4422.0','SQL Server 2016 Service Pack 1','CU2')
,('13.0.4411.0','SQL Server 2016 Service Pack 1','CU1')
,('13.0.4259.0','SQL Server 2016 Service Pack 1','GDR+SU4')
,('13.0.4224.16','SQL Server 2016 Service Pack 1','GDR+SU3')
,('13.0.4210.6','SQL Server 2016 Service Pack 1','GDR+SU2')
,('13.0.4206.0','SQL Server 2016 Service Pack 1','GDR+SU1')
,('13.0.4202.2','SQL Server 2016 Service Pack 1','GDR')
,('13.0.4199.0','SQL Server 2016 Service Pack 1','SP1+FIX')
,('13.0.4001.0','SQL Server 2016 Service Pack 1','SP1')
,('13.0.2218.0','SQL Server 2016','CU9+SU')
,('13.0.2216.0','SQL Server 2016','CU9')
,('13.0.2213.0','SQL Server 2016','CU8')
,('13.0.2210.0','SQL Server 2016','CU7')
,('13.0.2204.0','SQL Server 2016','CU6')
,('13.0.2197.0','SQL Server 2016','CU5')
,('13.0.2193.0','SQL Server 2016','CU4')
,('13.0.2186.6','SQL Server 2016','MS16-136')
,('13.0.2170.0','SQL Server 2016','CU2+FIX2')
,('13.0.2169.0','SQL Server 2016','CU2+FIX1')
,('13.0.2164.0','SQL Server 2016','CU2')
,('13.0.2149.0','SQL Server 2016','CU1')
,('13.0.1745.2','SQL Server 2016','GDR+SU2')
,('13.0.1742.0','SQL Server 2016','GDR+SU1')
,('13.0.1728.2','SQL Server 2016','GDR')
,('13.0.1722.0','SQL Server 2016','MS16-136')
,('13.0.1711.0','SQL Server 2016','FIX')
,('13.0.1708.0','SQL Server 2016','CU')
,('13.0.1601.5','SQL Server 2016','RTM')
,('13.0.1400.361','SQL Server 2016','RC3')
,('13.0.1300.275','SQL Server 2016','RC2')
,('13.0.1200.242','SQL Server 2016','RC1')
,('13.0.1100.288','SQL Server 2016','RC0')
,('13.0.1000.281','SQL Server 2016','CTP 3.3')
,('13.00.900.73','SQL Server 2016','CTP 3.2')
,('13.0.800.111','SQL Server 2016','CTP 3.1')
,('13.0.700.1395','SQL Server 2016','CTP 3.0')
,('13.0.600.65','SQL Server 2016','CTP 2.4')
,('13.0.500.53','SQL Server 2016','CTP 2.3')
,('13.0.407.1','SQL Server 2016','CTP 2.2')
,('13.0.400.91','SQL Server 2016','CTP 2.2')
,('13.0.300.44','SQL Server 2016','CTP 2.1')
,('13.0.200.172','SQL Server 2016','CTP 2.0')

,('12.0.6433.1','SQL Server 2014 Service Pack 3','CU4+SU2')
,('12.0.6372.1','SQL Server 2014 Service Pack 3','CU4+SU1')
,('12.0.6329.1','SQL Server 2014 Service Pack 3','CU4')
,('12.0.6293.0','SQL Server 2014 Service Pack 3','CU3+SU')
,('12.0.6259.0','SQL Server 2014 Service Pack 3','CU3')
,('12.0.6214.1','SQL Server 2014 Service Pack 3','CU2')
,('12.0.6205.1','SQL Server 2014 Service Pack 3','CU1')
,('12.0.6164.21','SQL Server 2014 Service Pack 3','GDR+SU3')
,('12.0.6118.4','SQL Server 2014 Service Pack 3','GDR+SU2')
,('12.0.6108.1','SQL Server 2014 Service Pack 3','GDR+SU1')
,('12.0.6024.0','SQL Server 2014 Service Pack 3','SP3')
,('12.0.5687.1','SQL Server 2014 Service Pack 2','CU18')
,('12.0.5659.1','SQL Server 2014 Service Pack 2','CU17+SU')
,('12.0.5632.1','SQL Server 2014 Service Pack 2','CU17')
,('12.0.5626.1','SQL Server 2014 Service Pack 2','CU16')
,('12.0.5605.1','SQL Server 2014 Service Pack 2','CU15')
,('12.0.5600.1','SQL Server 2014 Service Pack 2','CU14')
,('12.0.5590.1','SQL Server 2014 Service Pack 2','CU13')
,('12.0.5589.7','SQL Server 2014 Service Pack 2','CU12')
,('12.0.5579.0','SQL Server 2014 Service Pack 2','CU11')
,('12.0.5571.0','SQL Server 2014 Service Pack 2','CU10')
,('12.0.5563.0','SQL Server 2014 Service Pack 2','CU9')
,('12.0.5557.0','SQL Server 2014 Service Pack 2','CU8')
,('12.0.5556.0','SQL Server 2014 Service Pack 2','CU7')
,('12.0.5553.0','SQL Server 2014 Service Pack 2','CU6')
,('12.0.5546.0','SQL Server 2014 Service Pack 2','CU5')
,('12.0.5540.0','SQL Server 2014 Service Pack 2','CU4')
,('12.0.5538.0','SQL Server 2014 Service Pack 2','CU3')
,('12.0.5532.0','SQL Server 2014 Service Pack 2','MS16-136')
,('12.0.5522.0','SQL Server 2014 Service Pack 2','CU2')
,('12.0.5511.0','SQL Server 2014 Service Pack 2','CU1')
,('12.0.5223.6','SQL Server 2014 Service Pack 2','GDR+SU3')
,('12.0.5214.6','SQL Server 2014 Service Pack 2','GDR+SU2')
,('12.0.5207.0','SQL Server 2014 Service Pack 2','GDR+SU1')
,('12.0.5203.0','SQL Server 2014 Service Pack 2','MS16-136')
,('12.0.5000.0','SQL Server 2014 Service Pack 2','SP2')
,('12.0.4522.0','SQL Server 2014 Service Pack 1','CU13')
,('12.0.4511.0','SQL Server 2014 Service Pack 1','CU12')
,('12.0.4502.0','SQL Server 2014 Service Pack 1','CU11')
,('12.0.4491.0','SQL Server 2014 Service Pack 1','CU10')
,('12.0.4487.0','SQL Server 2014 Service Pack 1','MS16-136')
,('12.0.4474.0','SQL Server 2014 Service Pack 1','CU9')
,('12.0.4468.0','SQL Server 2014 Service Pack 1','CU8')
,('12.0.4463.0','SQL Server 2014 Service Pack 1','FIX')
,('12.0.4459.0','SQL Server 2014 Service Pack 1','CU7')
,('12.0.4457.0','SQL Server 2014 Service Pack 1','CU6')
,('12.0.4449.0','SQL Server 2014 Service Pack 1','CU6')
,('12.0.4439.1','SQL Server 2014 Service Pack 1','CU5')
,('12.0.4437.0','SQL Server 2014 Service Pack 1','CU4+FIX')
,('12.0.4436.0','SQL Server 2014 Service Pack 1','CU4')
,('12.0.4427.24','SQL Server 2014 Service Pack 1','CU3')
,('12.0.4422.0','SQL Server 2014 Service Pack 1','CU2')
,('12.0.4416.0','SQL Server 2014 Service Pack 1','CU1')
,('12.0.4237.0','SQL Server 2014 Service Pack 1','GDR+SU')
,('12.0.4232.0','SQL Server 2014 Service Pack 1','MS16-136')
,('12.0.4219.0','SQL Server 2014 Service Pack 1','TLS')
,('12.0.4213.0','SQL Server 2014 Service Pack 1','MS15-058')
,('12.0.4100.1','SQL Server 2014 Service Pack 1','SP1')
,('12.0.2569.0','SQL Server 2014','CU14')
,('12.0.2568.0','SQL Server 2014','CU13')
,('12.0.2564.0','SQL Server 2014','CU12')
,('12.0.2560.0','SQL Server 2014','CU11')
,('12.0.2556.4','SQL Server 2014','CU10')
,('12.0.2553.0','SQL Server 2014','CU9')
,('12.0.2548.0','SQL Server 2014','MS15-058')
,('12.0.2546.0','SQL Server 2014','CU8')
,('12.0.2495.0','SQL Server 2014','CU7')
,('12.0.2480.0','SQL Server 2014','CU6')
,('12.0.2474.0','SQL Server 2014','CU5+FIX')
,('12.0.2456.0','SQL Server 2014','CU5')
,('12.0.2430.0','SQL Server 2014','CU4')
,('12.0.2402.0','SQL Server 2014','CU3')
,('12.0.2381.0','SQL Server 2014','MS14-044')
,('12.0.2370.0','SQL Server 2014','CU2')
,('12.0.2342.0','SQL Server 2014','CU1')
,('12.0.2271.0','SQL Server 2014','TLS')
,('12.0.2269.0','SQL Server 2014','MS15-058')
,('12.0.2254.0','SQL Server 2014','MS14-044')
,('12.0.2000.8','SQL Server 2014','RTM')

,('11.0.7507.2','SQL Server 2012 Service Pack 4','GDR+SU2')
,('11.0.7493.4','SQL Server 2012 Service Pack 4','GDR+SU1')
,('11.0.7469.6','SQL Server 2012 Service Pack 4','GDR+FIX')
,('11.0.7462.6','SQL Server 2012 Service Pack 4','GDR')
,('11.0.7001.0','SQL Server 2012 Service Pack 4','SP4')
,('11.0.6615.2','SQL Server 2012 Service Pack 3','CU10+SU')
,('11.0.6607.3','SQL Server 2012 Service Pack 3','CU10')
,('11.0.6598.0','SQL Server 2012 Service Pack 3','CU9')
,('11.0.6594.0','SQL Server 2012 Service Pack 3','CU8')
,('11.0.6579.0','SQL Server 2012 Service Pack 3','CU7')
,('11.0.6567.0','SQL Server 2012 Service Pack 3','MS16-136')
,('11.0.6544.0','SQL Server 2012 Service Pack 3','CU5')
,('11.0.6540.0','SQL Server 2012 Service Pack 3','CU4')
,('11.0.6537.0','SQL Server 2012 Service Pack 3','CU3')
,('11.0.6523.0','SQL Server 2012 Service Pack 3','CU2')
,('11.0.6518.0','SQL Server 2012 Service Pack 3','CU1')
,('11.0.6260.1','SQL Server 2012 Service Pack 3','GDR+SU2')
,('11.0.6251.0','SQL Server 2012 Service Pack 3','GDR+SU1')
,('11.0.6248.0','SQL Server 2012 Service Pack 3','MS16-136')
,('11.0.6216.27','SQL Server 2012 Service Pack 3','TLS')
,('11.0.6020.0','SQL Server 2012 Service Pack 3','SP3')
,('11.0.5678.0','SQL Server 2012 Service Pack 2','CU16')
,('11.0.5676.0','SQL Server 2012 Service Pack 2','MS16-136')
,('11.0.5657.0','SQL Server 2012 Service Pack 2','CU14')
,('11.0.5655.0','SQL Server 2012 Service Pack 2','CU13')
,('11.0.5649.0','SQL Server 2012 Service Pack 2','CU12')
,('11.0.5646.0','SQL Server 2012 Service Pack 2','CU11')
,('11.0.5644.2','SQL Server 2012 Service Pack 2','CU10')
,('11.0.5641.0','SQL Server 2012 Service Pack 2','CU9')
,('11.0.5634.1','SQL Server 2012 Service Pack 2','CU8')
,('11.0.5623.0','SQL Server 2012 Service Pack 2','CU7')
,('11.0.5613.0','SQL Server 2012 Service Pack 2','MS15-058')
,('11.0.5592.0','SQL Server 2012 Service Pack 2','CU6')
,('11.0.5582.0','SQL Server 2012 Service Pack 2','CU5')
,('11.0.5571.0','SQL Server 2012 Service Pack 2','FIX')
,('11.0.5569.0','SQL Server 2012 Service Pack 2','CU4')
,('11.0.5556.0','SQL Server 2012 Service Pack 2','CU3')
,('11.0.5548.0','SQL Server 2012 Service Pack 2','CU2')
,('11.0.5532.0','SQL Server 2012 Service Pack 2','CU1')
,('11.0.5522.0','SQL Server 2012 Service Pack 2','FIX')
,('11.0.5388.0','SQL Server 2012 Service Pack 2','MS16-136')
,('11.0.5352.0','SQL Server 2012 Service Pack 2','TLS')
,('11.0.5343.0','SQL Server 2012 Service Pack 2','MS15-058')
,('11.0.5058.0','SQL Server 2012 Service Pack 2','SP2')
,('11.0.3513.0','SQL Server 2012 Service Pack 1','MS15-058')
,('11.0.3492.0','SQL Server 2012 Service Pack 1','CU16')
,('11.0.3487.0','SQL Server 2012 Service Pack 1','CU15')
,('11.0.3486.0','SQL Server 2012 Service Pack 1','CU14')
,('11.0.3482.0','SQL Server 2012 Service Pack 1','CU13')
,('11.0.3470.0','SQL Server 2012 Service Pack 1','CU12')
,('11.0.3467.0','SQL Server 2012 Service Pack 1','FIX')
,('11.0.3460.0','SQL Server 2012 Service Pack 1','MS14-044')
,('11.0.3449.0','SQL Server 2012 Service Pack 1','CU11')
,('11.0.3437.0','SQL Server 2012 Service Pack 1','FIX')
,('11.0.3431.0','SQL Server 2012 Service Pack 1','CU10')
,('11.0.3412.0','SQL Server 2012 Service Pack 1','CU9')
,('11.0.3401.0','SQL Server 2012 Service Pack 1','CU8')
,('11.0.3393.0','SQL Server 2012 Service Pack 1','CU7')
,('11.0.3381.0','SQL Server 2012 Service Pack 1','CU6')
,('11.0.3373.0','SQL Server 2012 Service Pack 1','CU5')
,('11.0.3368.0','SQL Server 2012 Service Pack 1','CU4')
,('11.0.3349.0','SQL Server 2012 Service Pack 1','CU3')
,('11.0.3339.0','SQL Server 2012 Service Pack 1','CU2')
,('11.0.3321.0','SQL Server 2012 Service Pack 1','CU1')
,('11.0.3156.0','SQL Server 2012 Service Pack 1','MS15-058')
,('11.0.3153.0','SQL Server 2012 Service Pack 1','MS14-044')
,('11.0.3128.0','SQL Server 2012 Service Pack 1','FIX')
,('11.0.3000.0','SQL Server 2012 Service Pack 1','SP1')
,('11.0.2424.0','SQL Server 2012','CU11')
,('11.0.2420.0','SQL Server 2012','CU10')
,('11.0.2419.0','SQL Server 2012','CU9')
,('11.0.2410.0','SQL Server 2012','CU8')
,('11.0.2405.0','SQL Server 2012','CU7')
,('11.0.2401.0','SQL Server 2012','CU6')
,('11.0.2395.0','SQL Server 2012','CU5')
,('11.0.2383.0','SQL Server 2012','CU4')
,('11.0.2376.0','SQL Server 2012','MS12-070')
,('11.0.2332.0','SQL Server 2012','CU3')
,('11.0.2325.0','SQL Server 2012','CU2')
,('11.0.2316.0','SQL Server 2012','CU1')
,('11.0.2218.0','SQL Server 2012','MS12-070')
,('11.0.2100.0','SQL Server 2012','RTM')

,('10.50.6560.0','SQL Server 2008 R2 Service Pack 3','GDR+SU')
,('10.50.6542.0','SQL Server 2008 R2 Service Pack 3','TLS')
,('10.50.6537.0','SQL Server 2008 R2 Service Pack 3','TLS')
,('10.50.6529.0','SQL Server 2008 R2 Service Pack 3','MS15-058')
,('10.50.6525.0','SQL Server 2008 R2 Service Pack 3','FIX')
,('10.50.6220.0','SQL Server 2008 R2 Service Pack 3','MS15-058')
,('10.50.6000.34','SQL Server 2008 R2 Service Pack 3','SP3')
,('10.50.4344.0','SQL Server 2008 R2 Service Pack 2','TLS')
,('10.50.4343.0','SQL Server 2008 R2 Service Pack 2','TLS')
,('10.50.4339.0','SQL Server 2008 R2 Service Pack 2','MS15-058')
,('10.50.4331.0','SQL Server 2008 R2 Service Pack 2','MS14-044')
,('10.50.4319.0','SQL Server 2008 R2 Service Pack 2','CU13')
,('10.50.4305.0','SQL Server 2008 R2 Service Pack 2','CU12')
,('10.50.4302.0','SQL Server 2008 R2 Service Pack 2','CU11')
,('10.50.4297.0','SQL Server 2008 R2 Service Pack 2','CU10')
,('10.50.4295.0','SQL Server 2008 R2 Service Pack 2','CU9')
,('10.50.4290.0','SQL Server 2008 R2 Service Pack 2','CU8')
,('10.50.4286.0','SQL Server 2008 R2 Service Pack 2','CU7')
,('10.50.4285.0','SQL Server 2008 R2 Service Pack 2','CU6')
,('10.50.4279.0','SQL Server 2008 R2 Service Pack 2','CU6')
,('10.50.4276.0','SQL Server 2008 R2 Service Pack 2','CU5')
,('10.50.4270.0','SQL Server 2008 R2 Service Pack 2','CU4')
,('10.50.4266.0','SQL Server 2008 R2 Service Pack 2','CU3')
,('10.50.4263.0','SQL Server 2008 R2 Service Pack 2','CU2')
,('10.50.4260.0','SQL Server 2008 R2 Service Pack 2','CU1')
,('10.50.4047.0','SQL Server 2008 R2 Service Pack 2','TLS')
,('10.50.4046.0','SQL Server 2008 R2 Service Pack 2','TLS')
,('10.50.4042.0','SQL Server 2008 R2 Service Pack 2','MS15-058')
,('10.50.4033.0','SQL Server 2008 R2 Service Pack 2','MS14-044')
,('10.50.4000.0','SQL Server 2008 R2 Service Pack 2','SP2')
,('10.50.2500.0','SQL Server 2008 R2 Service Pack 1','SP1')
,('10.50.1600.1','SQL Server 2008 R2','RTM')

,('10.00.6556.0','SQL Server 2008 Service Pack 4','GDR+SU')
,('10.00.6547.0','SQL Server 2008 Service Pack 4','TLS')
,('10.00.6543.0','SQL Server 2008 Service Pack 4','TLS')
,('10.00.6535.0','SQL Server 2008 Service Pack 4','MS15-058')
,('10.00.6526.0','SQL Server 2008 Service Pack 4','FIX')
,('10.00.6241.0','SQL Server 2008 Service Pack 4','MS15-058')
,('10.00.6000.0','SQL Server 2008 Service Pack 4','SP4')
,('10.00.5896.0','SQL Server 2008 Service Pack 3','TLS')
,('10.00.5894.0','SQL Server 2008 Service Pack 3','TLS')
,('10.00.5890.0','SQL Server 2008 Service Pack 3','MS15-058')
,('10.00.5869.0','SQL Server 2008 Service Pack 3','MS14-044')
,('10.00.5861.0','SQL Server 2008 Service Pack 3','CU17')
,('10.00.5852.0','SQL Server 2008 Service Pack 3','CU16')
,('10.00.5850.0','SQL Server 2008 Service Pack 3','CU15')
,('10.00.5848.0','SQL Server 2008 Service Pack 3','CU14')
,('10.00.5846.0','SQL Server 2008 Service Pack 3','CU13')
,('10.00.5844.0','SQL Server 2008 Service Pack 3','CU12')
,('10.00.5841.0','SQL Server 2008 Service Pack 3','CU11')
,('10.00.5840.0','SQL Server 2008 Service Pack 3','CU11')
,('10.00.5835.0','SQL Server 2008 Service Pack 3','CU10')
,('10.00.5829.0','SQL Server 2008 Service Pack 3','CU9')
,('10.00.5828.0','SQL Server 2008 Service Pack 3','CU8')
,('10.00.5826.0','SQL Server 2008 Service Pack 3','MS12-070')
,('10.00.5794.0','SQL Server 2008 Service Pack 3','CU7')
,('10.00.5788.0','SQL Server 2008 Service Pack 3','CU6')
,('10.00.5785.0','SQL Server 2008 Service Pack 3','CU5')
,('10.00.5775.0','SQL Server 2008 Service Pack 3','CU4')
,('10.00.5770.0','SQL Server 2008 Service Pack 3','CU3')
,('10.00.5768.0','SQL Server 2008 Service Pack 3','CU2')
,('10.00.5766.0','SQL Server 2008 Service Pack 3','CU1')
,('10.00.5545.0','SQL Server 2008 Service Pack 3','TLS')
,('10.00.5544.0','SQL Server 2008 Service Pack 3','TLS')
,('10.00.5538.0','SQL Server 2008 Service Pack 3','MS15-058')
,('10.00.5520.0','SQL Server 2008 Service Pack 3','MS14-044')
,('10.00.5512.0','SQL Server 2008 Service Pack 3','MS12-070')
,('10.00.5500.0','SQL Server 2008 Service Pack 3','SP3')
,('10.00.4000.0','SQL Server 2008 Service Pack 2','SP2')
,('10.00.2531.0','SQL Server 2008 Service Pack 1','SP1')
,('10.00.1600.0','SQL Server 2008','RTM')

;

RETURN ;

END ;

GO
