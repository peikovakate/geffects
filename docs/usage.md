# nf-core/geffects: Usage

## Parameters 

### Mash parameters

#### `--susie_files`
A tsv file with two columns: susie file and dataset name. The listed datasets there are used to build connected components of gene-variants pairs. The obtained pairs are queried later from QTL summary statistics. (Example `data/susie_ge.tsv`).

#### `--sumstat_path`
Path to directory with sumstat files. All datasets that are present in the folder will be queried for varaints. 

---

### Matrix factorization parameters

#### `--effects`
File with lead effects extracted with mash.nf pipeline. Located in the `results/lead_effects_na.tsv`. (Alternatively can be any other subset of effects in a relative format.)

#### `--factor_params`
File with three lines (factors, alpha1, lambda1) of parameters search space. Each line is a list of numbers separated by a white space. (Example `data/factor_params.txt`). Define for first and second level of the grid search. 

#### `--colors`
Text file with dataset names and colors. (Example `data/colors.txt`). Needed for plots of each matrix. 

#### `--iter` 
Integer. Number of iterations for matrix factorization. 

#### `--second_level`
Logical. Identifies this is the second level of grid search. 

#### `--runs`
Integer. Number of runs each set of parameters will be tested in second level of the grid search. Each set of parameters will have a `--runs` number of candidate matricies. Used with `--second_level`. 

#### `--mapping`
Logical. Weather to perform mapping of effects to factor matrix. 

#### `--mapping_matrix`
Directory name with final matrix based on the results of the second level grid search. For example, `sn_spMF_K20_a11100_l11200`.

#### `--matrix_folder`
Folder with the second level grid search results. (`results/factorization/grid_search`). 

---

## How to run

### Mash

```
nextflow run main.nf -resume -profile tartu_hpc \
  --susie_files data/susie_ge.tsv
```

### Matrix factorization

At first, do two levels of parameters grid search.
Then, pick the best matrix and map variants to it. 


**First level**

Make sure that factors parameter should be smaller than number of datasets.   

```
nextflow run factorization.nf -resume -profile tartu_hpc \
  --effects results/lead_effects_na.tsv \
  --factor_params data/factor_params.txt \
  --colors data/colors.txt \
  --iter 10
```

Output in `results/factorization/grid_search` contains folders with matricies and `first_level_results.txt`.

**Second level**

Update parameters space (factor_params.txt) based on `first_level_results.txt`.

```
nextflow run factorization.nf -resume -profile tartu_hpc \
  --effects results/lead_effects_na.tsv \
  --factor_params data/factor_params.txt \
  --second_level \
  --colors data/colors.txt \
  --iter 20 \
  --runs 10
```

**Mapping**

Pick the best matrix and map the variant-gene pairs.

```
nextflow run factorization.nf -resume -profile tartu_hpc \
  --effects results/lead_effects_na.tsv \
  --mapping \
  --mapping_matrix sn_spMF_K20_a11100_l11200 
```