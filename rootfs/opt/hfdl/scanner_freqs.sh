#shellcheck shell=bash
##name for the frequency group
fname=()

#frequency group. frequencies below 5MHz are not included due to very low activity.
# For less-powerful processors or 8-bit sdrs add more frequency groups containing a lower frequency spread in each group
freq=()

# group 1
fname+=("11M13M")
freq+=("11306 11312 11318 11321 11327 11348 11354 11384 11387 11184 11306")

fname+=("11M13Mx2")
freq+=("13264 13270 13276 13303 13312 13315 13321 13324 13342 13351 13354")

# group 2
fname+=("5M6M")
freq+=("5451 5502 5508 5514 5529 5538 5544 5547 5583 5589 5622 5652 5655 5720")

fname+=(5M6Mx2)
freq+=("6529 6535 6559 6565 6589 6619 6661")

# group 3
fname+=("8M10M")
freq+=("8825 8834 8843 8851 8885 8886 8894 8912 8921 8927 8936 8939 8942 8948 8957 8977")

fname+=("8M10Mx2")
freq+=("10027 10060 10063 10066 10075 10081 10084 10087 10093")

# group 4
fname+=("17M")
freq+=("17901 17912 17916 17919 17922 17928 17934 17958 17967")

# group 5
fname+=("21M")
freq+=("21928 21931 21934 21937 21949 21955 21982 21990 21995 21997")
