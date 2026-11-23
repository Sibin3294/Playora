import { Schema, model, type InferSchemaType } from 'mongoose';

const catalogDocSchema = new Schema(
  {
    key: { type: String, required: true, unique: true, index: true },
    data: { type: Schema.Types.Mixed, required: true },
  },
  { timestamps: true },
);

export type CatalogDoc = InferSchemaType<typeof catalogDocSchema> & {
  _id: Schema.Types.ObjectId;
};

export const CatalogDocument = model('CatalogDocument', catalogDocSchema);
