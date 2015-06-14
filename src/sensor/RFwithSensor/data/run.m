clc;clear;

%{
load data.txt
savesize=150;
testruns=3;

for i=0:(testruns-1)

    data2(i+1,:)=mean(data(((savesize*i+1):(savesize*(i+1))),:));

end


csvwrite('data2.txt',data2);

%}


load mean.txt

x=mean;
mean(x)

