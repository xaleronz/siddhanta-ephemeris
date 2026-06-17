# siddhanta-ephemeris

A small, self-hostable HTTP service exposing **sidereal (Vedic) astronomical
primitives** — planet positions, house cusps, and rise/set times — computed with
[Swiss Ephemeris](https://www.astro.com/swisseph/). Defaults to **Lahiri
ayanamsa** and **Whole-Sign houses**. **AGPL-3.0-or-later.**

## Why a separate service?

Swiss Ephemeris (`pyswisseph`) is dual-licensed: **AGPL-3.0** or a paid
Astrodienst commercial license. Running it inside a closed-source application
would, under the AGPL, oblige you to release that application's source.

This service isolates Swiss Ephemeris behind a network boundary so a separate,
proprietary application can consume ephemeris data **over HTTP without linking
`swisseph`** — the application is then a distinct work and only *this* service
(which contains no application logic, just standard astronomy) is AGPL:

```
  your proprietary app  ──HTTP──▶  siddhanta-ephemeris (AGPL, swisseph)
```

(Confirm the network-boundary reasoning for your situation with a lawyer; it is
the standard interpretation, but the boundary is the crux.)

## API

All `/v1` routes require header `X-Ephemeris-Key` **iff** `EPHEMERIS_API_KEY` is set.

| Method | Path | Body | Returns |
|---|---|---|---|
| GET | `/health` | — | `{status}` |
| GET | `/source` | — | `{license, source}` (AGPL §13 offer) |
| POST | `/v1/positions` | `{jd_ut, bodies:[int], speed?}` | `{positions: {body: [lon,lat,dist,lon_spd,lat_spd,dist_spd]}}` (sidereal) |
| POST | `/v1/houses` | `{jd_ut, lat, lng, hsys?="W"}` | `{cusps:[…], ascmc:[…]}` |
| POST | `/v1/rise-transit` | `{jd_ut, body, event:"rise"\|"set", lat, lng, alt?, atpress?, attemp?}` | `{status, jd}` |

`bodies` are the standard Swiss Ephemeris constants (Sun=0 … Saturn=6, mean
node=10). Julian-day conversion (`julday`/`revjul`) is plain calendar math and is
left to the caller.

## Run / test

```bash
pip install -r requirements-dev.txt
pytest tests/ -q
uvicorn main:app --reload
```

## Deploy

1. Source is published under AGPL-3.0 (full text in `LICENSE`); the `/source`
   endpoint serves the §13 offer (override the repo URL via `SOURCE_URL` if you
   fork/move it). **Keep the published source in sync with what you deploy.**
2. Deploy the provided `Dockerfile`. Single worker — libswe is not thread-safe; scale with instances, not threads.
3. Set `EPHEMERIS_API_KEY` (shared with your caller) and, if you ship `.se1` data files, `EPHE_PATH`.

## Status

The service is complete and its tests cross-check every result against
`swisseph` directly, so it is a faithful drop-in for callers migrating off a
direct `pyswisseph` dependency.
