# Vcard [![Build Status](https://travis-ci.org/qoobaa/vcard.svg?branch=master)](https://travis-ci.org/qoobaa/vcard)

Vcard gem extracts Vcard support from Vpim gem.

## Installation

Add this line to your application's Gemfile:

    gem "vcard"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vcard

## Configuration

You can configure how to make deal with invalid lines.
Gem supports three behaviors:
1. `raise_on_invalid_line = true`
  Vcard::InvalidEncodingError will be races if any invalid line will be found

2. `raise_on_invalid_line = false, ignore_invalid_vcards = true`
  If vcard source has invalid line, then this vcard object will be ignored.
  In case if you have only one vcard object in your source string, empty array will be returned from `Vcard.decode`

3. `raise_on_invalid_line = false, ignore_invalid_vcards = false`
  vcard will be marked as invalid, invalid field will be ignored, but vcard will be present in `Vcard#decode` results

    Vcard.configure do |config|
      config.raise_on_invalid_line = false # default true
      config.ignore_invalid_vcards = false  # default true
    end

## Upgrade Notes

We are no longer testing against Ruby 1.8.7.
