## RPC

This code implements the RPC saliency detection algorithm in the following paper:

Jing Lou, Mingwu Ren, Huan Wang, "Regional Principal Color Based Saliency Detection," PLoS ONE, vol. 9, no. 11, pp. e112475: 1-13, 2014. [doi:10.1371/journal.pone.0112475](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0112475)
 
Project page: [http://www.loujing.com/rpc-saliency/](http://www.loujing.com/rpc-saliency/)
 
Copyright (C) 2016 [Jing Lou (楼竞)](http://www.loujing.com/)
 
Date: Jul 31, 2016


### Notes:

 1. This algorithm can be run in a row by the command:
 	```matlab
	>>Demo
	```

 2. This algorithm reads the input images from the folder `images`, and generates two resulting folders:
	 1. `GloSalMaps`  global saliency maps
	 2. `RegSalMaps`  regional saliency maps (final retults)
