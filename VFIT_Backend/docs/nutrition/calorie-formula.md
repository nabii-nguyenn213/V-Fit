# V-FIT nutrition calculator formula

The Excel source contains a base serving in the `Gram` column. Some foods are
listed per 100g, while others are listed per one serving. Store both the base
serving and base macros, then calculate client-side without calling the camera
or backend again.

```text
calories_current = input_grams / serving_size_grams * calories
protein_current  = input_grams / serving_size_grams * protein
carbs_current    = input_grams / serving_size_grams * carbs
fat_current      = input_grams / serving_size_grams * fat
```

For foods that are truly per 100g, `serving_size_grams = 100`, so this becomes:

```text
calories_current = input_grams / 100 * calories_per_100g
```
