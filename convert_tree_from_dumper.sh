cd /media/giulia/DATA/DATASETS/iCubWorld30_nocrop

mkdir train test

cd train
mkdir lunedi22
mkdir martedi23
mkdir mercoledi24
mkdir venerdi26
cd .. 

cd test
mkdir lunedi22
mkdir martedi23
mkdir mercoledi24
mkdir venerdi26
cd ..

mv lunedi22/train/* train/lunedi22
mv martedi23/train/* train/martedi23
mv mercoledi24/train/* train/mercoledi24
mv venerdi26/train/* train/venerdi26

mv lunedi22/test/* test/lunedi22
mv martedi23/test/* test/martedi23
mv mercoledi24/test/* test/mercoledi24
mv venerdi26/test/* test/venerdi26

rm -r lunedi22 martedi23 mercoledi24 venerdi26

cd train/lunedi22
cd train/martedi23
cd train/mercoledi24
cd train/venerdi26

cd test/lunedi22
cd test/martedi23
cd test/mercoledi24
cd test/venerdi26

mkdir tmp1 tmp2 tmp3 tmp4 tmp5 tmp6 tmp7
mv dish* tmp1
mv laundrydetergent* tmp2
mv mug* tmp3
mv soap* tmp4
mv sponge* tmp5
mv sprinkler* tmp6
mv washingup* tmp7

mv tmp1 dish
mv tmp2 laundrydetergent
mv tmp3 mug
mv tmp4 soap
mv tmp5 sponge
mv tmp6 sprinkler
mv tmp7 washingup

cd ..


