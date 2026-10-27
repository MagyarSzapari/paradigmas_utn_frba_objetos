# Paradigmas de Programación — Paradigma de Objetos (Wollok)

Código de la cursada de **Paradigmas de Programación** (UTN FRBA) correspondiente al paradigma orientado a objetos, escrito en **Wollok**.

## Estructura

```
paradigmas-objetos-wollok/
├── tp-neflis/              TP 2023 — NeFlis
│   ├── cuenta.wlk          Modelo final
│   ├── test.wtest          Tests
│   ├── historial/          Versión de la primera entrega
│   └── docs/               Enunciado y código entregado (PDF)
└── parciales/              Parciales de práctica (código + enunciado)
    ├── antivirus/  pokemon/  yaaar/
```

## Cómo correrlo

Con [Wollok-TS CLI](https://github.com/uqbar-project/wollok-ts-cli) (`npm i -g wollok-ts-cli`):

```bash
cd tp-neflis
wollok test
```

## Refactor (v2.0)

`refactored/` es un proyecto Wollok-TS con el TP y los parciales reescritos en inglés, con 136 tests:

```bash
cd refactored
wollok test
```

Justificación de cada cambio y bugs encontrados en los originales: [`docs/REFACTOR.md`](docs/REFACTOR.md).
