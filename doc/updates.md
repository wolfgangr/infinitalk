## 2021-01-20  rendering status

we have
```
...   ./tmp$ ls *.bck
conf0.bck  conf1.bck  conf2.bck  conf3.bck  em.bck  stat.bck  status.bck
```

Where the last state is dropped as PERL `Storable` hash at every complete readout.  
Information is more comprehensive than in rrds and also contains config.  

Grouping and labelling of this status is configured in `P17_def.pl`  
It is derived from infini protocol definition and contains most registers provided there.  
Register, field and enum variable content names are provided in readable text.  
It is intended to replace configuration software.

TODO: some buttons for config changes, at least for some sanitized subset  



We have two html status renderer:  

#### status-simple.pl
Simple log vertical list with variables per line.  
May be used to grep, to import, to copy to some editor or as a boilerplate for customized status views.  

#### status-compact.pl  
Much more compressed HTML view with elaborated tables.  
Optimized for human reading, maybe in a frame of the charting renderer.  
Contains a nav/select bar for rough customisation.  



