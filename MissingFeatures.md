# Missing features

The following features not included in Terrestrial are omitted purposefully to
keep the library simple and encourage good practices in application code.

Please open an issue if you feel like any of these features are essential or if
you think you can contribute to a solution please open an issue to discuss.

## The 'session'

When people think of data mappers they often think of
[Hibernate and its sessions](http://www.tutorialspoint.com/hibernate/hibernate_sessions.htm).
Terrestrial has no session or abstraction on top of the database transaction,
changes to a single object graph are persisted within a transaction to avoid
local inconsistency should something go wrong.

However, if several different graphs are separately loaded and modified they
will each persist within their own transactions.

Managing these multiple change sets along with what particular transaction
isolation levels might be required is left as an exercise to the user. This may
of course be as easy as wrapping your controller code in
`DB.transaction do ...`

## Coercion

Database supported types will be returned as expected, `Fixnum`, `DateTime`, `nil` etc.
Should you wish to enhance this data, every row is passed into the mapping's
factory function where you have the opportunity to do arbitrary transformations
before instantiating the domain object.

\*see note on transforming row data

## Validation

This is the concern of your domain model and/or application boundaries.
Terrestrial allows you to persist any object you wish assuming schema
compatibility.

## Database column name aliasing

While at first glance this is a simple feature, the abstraction starts to leak
when the using the query interface and guaranteeing all queries are substituted
perfectly is beyond the scope of the current version.

Should you wish to simply pass a column's key with a different parameter name
then you can again lean on the factory function to transform the row's data
before the domain object receives it.

\*see note on transforming row data

## Cascade deletion

This is chiefly a data concern and is handled by a good database more
efficiently and effectively than any ORM could hope.

## Database generated IDs and timestamps

While database generated values may work, available only after an object is
retrieved, they are not currently supported.

Data important to your domain should be generated in your application layer.
UUIDs make much more flexible identifiers for domain objects and further enable
decoupling and fast tests.

Timestamps are useful and important to most applications however if they are
used in your domain they should be pushed from explicitly from application
layer. You should again find this affords you more flexibility and decoupling.

There is absolutely nothing wrong with data added at time of persistence for
auditing purposes but Terrestrial will make you actively decide whether this
data should be available to the domain and what should be explicitly added.

\* Transforming row data

Adding a custom factory method to transform row data before passing it to the
domain layer is highly encouraged. However, ensure that for each custom factory
a serializer function is also supplied that Terrestrial can use to reverse the
operation for persistence.

