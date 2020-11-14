[d si h] = abfload('12403015_2.abf');
x = d(:,2,1);
y = diff(x);


figure,
plot(x)
title('trace')
figure,
plot(y)
title('dvdt') 
figure,
plot(x(1:end-1),y)
