for image in `ls Segmentations`; do

  echo "Processing $image"

  # Replace labels defined as CSF, GM, WM, etc by Nick
  # Then threshold out anything else

  c3d Segmentations/$image -replace \
	4	1 \
	46	1 \
	49	1 \
	50	1 \
	51	1 \
	52	1 \
	31	2 \
	32	2 \
	42	2 \
	43	2 \
	47	2 \
	48	2 \
	100	2 \
	101	2 \
	102	2 \
	103	2 \
	104	2 \
	105	2 \
	106	2 \
	107	2 \
	108	2 \
	109	2 \
	112	2 \
	113	2 \
	114	2 \
	115	2 \
	116	2 \
	117	2 \
	118	2 \
	119	2 \
	120	2 \
	121	2 \
	122	2 \
	123	2 \
	124	2 \
	125	2 \
	128	2 \
	129	2 \
	132	2 \
	133	2 \
	134	2 \
	135	2 \
	136	2 \
	137	2 \
	138	2 \
	139	2 \
	140	2 \
	141	2 \
	142	2 \
	143	2 \
	144	2 \
	145	2 \
	146	2 \
	147	2 \
	148	2 \
	149	2 \
	150	2 \
	151	2 \
	152	2 \
	153	2 \
	154	2 \
	155	2 \
	156	2 \
	157	2 \
	160	2 \
	161	2 \
	162	2 \
	163	2 \
	164	2 \
	165	2 \
	166	2 \
	167	2 \
	168	2 \
	169	2 \
	170	2 \
	171	2 \
	172	2 \
	173	2 \
	174	2 \
	175	2 \
	176	2 \
	177	2 \
	178	2 \
	179	2 \
	180	2 \
	181	2 \
	182	2 \
	183	2 \
	184	2 \
	185	2 \
	186	2 \
	187	2 \
	190	2 \
	191	2 \
	192	2 \
	193	2 \
	194	2 \
	195	2 \
	196	2 \
	197	2 \
	198	2 \
	199	2 \
	200	2 \
	201	2 \
	202	2 \
	203	2 \
	204	2 \
	205	2 \
	206	2 \
	207	2 \
	44	3 \
	45	3 \
	23	4 \
	30	4 \
	36	4 \
	37	4 \
	55	4 \
	56	4 \
	57	4 \
	58	4 \
	59	4 \
	60	4 \
	61	4 \
	62	4 \
	63	4 \
	64	4 \
	75	4 \
	76	4 \
	35	5 \
	11	6 \
	38	6 \
	39	6 \
	40	6 \
	41	6 \
	71	6 \
	72	6 \
	73	6 \
        -dup -thresh 1 6 1 0 -multiply -o Segmentations6Class/$image
 
done 
