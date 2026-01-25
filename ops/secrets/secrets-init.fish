set AGE_KEY ~/.config/sops/age/keys.txt

if test -f $AGE_KEY
    grep "public" $AGE_KEY
    exit 0
end

mkdir -p (dirname $AGE_KEY)
age-keygen -o $AGE_KEY
grep "public" $AGE_KEY
