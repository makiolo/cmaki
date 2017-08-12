if [[ ! -d node_modules/cmaki ]]; then
	mkdir -p node_modules/cmaki
	(cd node_modules && git clone https://github.com/makiolo/cmaki.git)
fi

