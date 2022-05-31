montage 1.jpg -tile 1x1 -geometry +5+5 -background black one.png
montage 2.jpg 3.jpg 4.jpg 5.jpg 6.jpg 7.jpg -tile 3x2 -geometry 145x145+5+5 -background black ten.png
montage 8.jpg 9.jpg 10.jpg 11.jpg 12.jpg 13.jpg 14.jpg 15.jpg 16.jpg 17.jpg 18.jpg 19.jpg -tile 6x2 -geometry 123x123+3+3 -background black teens.png
montage teens.png -tile 1x1 -geometry +2+2 -background black teens_border.png
montage 20.jpg 21.jpg 22.jpg 23.jpg 24.jpg 25.jpg 26.jpg 27.jpg 28.jpg 29.jpg 30.jpg 31.jpg 32.jpg 33.jpg 34.jpg 35.jpg 36.jpg 37.jpg 38.jpg -tile 10x2 -geometry 73x73+2+2 -background black twenties.png
montage 39.jpg 40.jpg 41.jpg 42.jpg -tile 2x2 -geometry 35x35+1+1 -background black theend.png


montage 1.jpg 2.jpg 3.jpg 4.jpg 5.jpg 6.jpg 7.jpg 8.jpg 9.jpg 10.jpg -tile 5x2 -geometry 300x300+5+5 -background black x_ten.png
montage 11.jpg 12.jpg 13.jpg 14.jpg 15.jpg 16.jpg 17.jpg 18.jpg 19.jpg 20.jpg 21.jpg 22.jpg -tile 6x2 -geometry 250x250+3+3 -background black x_teens.png
montage x_teens.png -tile 1x1 -geometry +2+2 -background black x_teens_border.png
montage 23.jpg 24.jpg 25.jpg 26.jpg 27.jpg 28.jpg 29.jpg 30.jpg 31.jpg 32.jpg 33.jpg 34.jpg 35.jpg 36.jpg 37.jpg 38.jpg 39.jpg 40.jpg 41.jpg 42.jpg -tile 10x2 -geometry 150x150+2+2 -background black x_thirties.png
montage x_thirties.png -tile 1x1 -geometry +3+3 -background black x_thirties_border.png
montage x_ten.png x_teens_border.png x_thirties_border.png -tile 1x3 -geometry +0+0  -background black x_out.png
montage x_out.png -tile 1x1 -geometry +10+10 -background black x_out_border.png
