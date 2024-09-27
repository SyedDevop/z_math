# Z Math (CLI Calculator App)

A powerful and simple command-line calculator that evaluates mathematical
expressions and supports unit conversions for length and area. This tool is
designed to help users calculate expressions and convert between commonly used
units directly from the terminal.

<!--toc:start-->

- [Z Math (CLI Calculator App)](#z-math-cli-calculator-app)
  - [Features](#features)
  - [Usage](#usage)
    - [1. Math Operations](#1-math-operations)
    - [2. Length Conversion](#2-length-conversion)
    - [3. Area Conversion](#3-area-conversion)
  - [Supported Units](#supported-units)
    - [Length](#length)
    - [Area](#area)
  - [TODO](#todo)
  <!--toc:end-->

## Features

- Evaluate mathematical expressions (addition, subtraction, multiplication,
  division, and more)
- Support for parentheses and operator precedence
- Convert between units of length (e.g., meters, kilometers, miles, inches,
  etc.)
- Convert between units of area (e.g., square meters, square kilometers, acres,
  hectares, etc.)
- Simple and intuitive command-line interface

## Usage

### 1. Math Operations

You can input basic math expressions directly:

```bash
$ m "2 + 3 * (4 - 1)"
The input is ::  2 + 3 * (4 - 1)  ::
Ans: 11
```

### 2. Length Conversion

Convert units of length:

```bash
# Convert 5 meters to kilometers
$ m len "m:5:km"
Ans: 0.005 km

# Convert 10 miles to meters
$ m len "mi:10:m"
Result: 16093.4 m
```

### 3. Area Conversion

Convert units of area:

```bash
# Convert 100 square meters to acres
$ m area "m2:100:a"
Ans: 0.0247 acres

# Convert 1 hectare to square kilometers
$ m area "h:1:km2"
Ans: 0.01 sqkm
```

## Supported Units

### Length

- Meters (m)
- Kilometers (km)
- Miles (mi)
- Inches (in)
- Feet (ft)

### Area

- Square meters (sqm)
- Square kilometers (sqkm)
- Acres
- Hectares

## TODO

## REF

- [CLI](https://github.com/prajwalch/yazap)
