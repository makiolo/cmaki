if [[ -d cmaki ]]; then
	rm -Rf cmaki
fi
git clone https://github.com/makiolo/cmaki.git

if [[ -d cmaki_generator ]]; then
	rm -Rf cmaki_generator
fi
git clone https://github.com/makiolo/cmaki_generator.git

